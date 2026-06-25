import json
import boto3
import base64
import gzip
import urllib.parse
import time
import os

s3 = boto3.client("s3")
firehose = boto3.client("firehose")

FIREHOSE_STREAM = os.environ["FIREHOSE_STREAM"]
MAX_RETRIES = int(os.environ.get("MAX_RETRIES", "3"))
DLQ_PREFIX = os.environ.get("DLQ_PREFIX", "errors/deadletter/")
BATCH_SIZE = 500
MAX_BATCH_REPLAY_ATTEMPTS = 3

# =========================
# RAW DATA DECODER (REQUIRED)
# =========================
def decode_raw_data(raw_data: str) -> str:
    decoded = base64.b64decode(raw_data)

    if decoded[:2] == b"\x1f\x8b":
        decoded = gzip.decompress(decoded)

    return decoded.decode("utf-8", errors="replace")


# =========================
# RETRY HANDLING
# =========================
def get_retry_count(bucket, key):
    try:
        response = s3.get_object_tagging(Bucket=bucket, Key=key)
        tags = {t["Key"]: t["Value"] for t in response.get("TagSet", [])}
        return int(tags.get("retryCount", "0")), response.get("TagSet", [])
    except Exception:
        return 0, []


def update_retry_count(bucket, key, existing_tags, retry_count):
    filtered = [t for t in existing_tags if t["Key"] != "retryCount"]

    filtered.append({
        "Key": "retryCount",
        "Value": str(retry_count)
    })

    s3.put_object_tagging(
        Bucket=bucket,
        Key=key,
        Tagging={"TagSet": filtered}
    )


# =========================
# DLQ HANDLING
# =========================
def move_to_deadletter(bucket, key, retry_count):
    dlq_key = f"{DLQ_PREFIX}{key}"

    s3.copy_object(
        Bucket=bucket,
        CopySource={
            "Bucket": bucket,
            "Key": key
        },
        Key=dlq_key
    )

    s3.put_object_tagging(
        Bucket=bucket,
        Key=dlq_key,
        Tagging={
            "TagSet": [
                {
                    "Key": "deadLettered",
                    "Value": "true"
                },
                {
                    "Key": "retryCount",
                    "Value": str(retry_count)
                }
            ]
        }
    )

    s3.delete_object(
        Bucket=bucket,
        Key=key
    )

    print(
        f"DEADLETTER bucket={bucket} "
        f"source_key={key} "
        f"target_key={dlq_key} "
        f"retry_count={retry_count}"
    )


# =========================
# FIREHOSE
# =========================
def flush(records):
    if not records:
        return

    pending = records

    for attempt in range(1, MAX_BATCH_REPLAY_ATTEMPTS + 1):
        resp = firehose.put_record_batch(
            DeliveryStreamName=FIREHOSE_STREAM,
            Records=pending
        )

        failed = resp.get("FailedPutCount", 0)
        print(f"Sent {len(pending)} records on attempt {attempt}, failed={failed}")

        if failed == 0:
            return

        responses = resp.get("RequestResponses", [])
        if len(responses) != len(pending):
            raise Exception("Firehose batch response count did not match request count")

        failed_records = []
        error_codes = {}

        for index, result in enumerate(responses):
            error_code = result.get("ErrorCode")
            if error_code:
                failed_records.append(pending[index])
                error_codes[error_code] = error_codes.get(error_code, 0) + 1

        print(f"Retrying {len(failed_records)} failed records: {error_codes}")
        pending = failed_records

        if attempt < MAX_BATCH_REPLAY_ATTEMPTS:
            time.sleep(min(2 ** attempt, 8))

    raise Exception(
        f"Firehose batch failed after {MAX_BATCH_REPLAY_ATTEMPTS} attempts for {len(pending)} records"
    )

# =========================
# LAMBDA HANDLER
# =========================
def lambda_handler(event, context):

    batch = []

    for record in event["Records"]:

        body = json.loads(record["body"])

        for s3rec in body["Records"]:

            bucket = s3rec["s3"]["bucket"]["name"]
            key = urllib.parse.unquote_plus(s3rec["s3"]["object"]["key"])

            print(f"Processing s3://{bucket}/{key}")

            retry_count, tags = get_retry_count(bucket, key)

            if retry_count >= MAX_RETRIES:
                move_to_deadletter(
                    bucket,
                    key,
                    retry_count
                )
                continue

            try:

                obj = s3.get_object(Bucket=bucket, Key=key)
                raw_bytes = obj["Body"].read()

                if raw_bytes[:2] == b"\x1f\x8b":
                    decompressed = gzip.decompress(raw_bytes)
                else:
                    decompressed = raw_bytes

                text = decompressed.decode("utf-8", errors="replace")

                for line in text.splitlines():

                    if not line.strip():
                        continue

                    try:
                        event_obj = json.loads(line)
                    except Exception as e:
                        print(f"Bad JSON line: {e}")
                        continue

                    raw_data = event_obj.get("rawData")
                    if not raw_data:
                        continue

                    try:
                        log_line = decode_raw_data(raw_data)
                    except Exception as e:
                        print(f"Decode failed: {e}")
                        continue

                    batch.append({
                        "Data": (log_line + "\n").encode("utf-8")
                    })

                    if len(batch) >= BATCH_SIZE:
                        flush(batch)
                        batch = []

            except Exception as e:

                update_retry_count(
                    bucket,
                    key,
                    tags,
                    retry_count + 1
                )

                print(
                    f"Replay failed for s3://{bucket}/{key}, "
                    f"retryCount={retry_count + 1}, "
                    f"error={str(e)}"
                )

                raise

    if batch:
        flush(batch)

    return {"statusCode": 200}