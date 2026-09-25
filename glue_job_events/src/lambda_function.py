import json
import os
import urllib.error
import urllib.request

import boto3


_secrets_client = boto3.client("secretsmanager")
_token = None


def _get_token():
    global _token
    if _token is not None:
        return _token

    response = _secrets_client.get_secret_value(SecretId=os.environ["TOKEN_SECRET_ARN"])
    secret = response["SecretString"]
    json_key = os.environ.get("TOKEN_JSON_KEY")
    _token = json.loads(secret)[json_key] if json_key else secret
    return _token


def _normalise_event(event):
    detail = event.get("detail", {})
    if event.get("detail-type") == "AWS API Call via CloudTrail":
        request = detail.get("requestParameters") or {}
        response = detail.get("responseElements") or {}
        return {
            "job_name": request.get("jobName", "unknown"),
            "job_run_id": response.get("jobRunId", "unknown"),
            "state": "START_REQUESTED",
            "message": "AWS Glue StartJobRun was called",
        }

    return {
        "job_name": detail.get("jobName", "unknown"),
        "job_run_id": detail.get("jobRunId", "unknown"),
        "state": detail.get("state", "UNKNOWN"),
        "message": detail.get("message", "AWS Glue job state changed"),
    }


def lambda_handler(event, _context):
    detail = event.get("detail", {})
    if (
        event.get("detail-type") == "AWS API Call via CloudTrail"
        and detail.get("errorCode")
    ):
        return {"status": "ignored", "reason": "StartJobRun failed"}

    glue_event = _normalise_event(event)
    alert_states = set(filter(None, os.environ.get("ALERT_STATES", "").split(",")))
    event_type = "CUSTOM_ALERT" if glue_event["state"] in alert_states else "CUSTOM_INFO"
    payload = {
        "eventType": event_type,
        "title": f"AWS Glue job {glue_event['state'].lower()}: {glue_event['job_name']}",
        "timeout": int(os.environ["EVENT_TIMEOUT_MINUTES"]),
        "properties": {
            "aws.account.id": event.get("account", "unknown"),
            "aws.region": event.get("region", "unknown"),
            "aws.glue.job.name": glue_event["job_name"],
            "aws.glue.job.run.id": glue_event["job_run_id"],
            "aws.glue.job.state": glue_event["state"],
            "eventbridge.event.id": event.get("id", "unknown"),
            "event.description": glue_event["message"],
        },
    }

    endpoint = f"{os.environ['DYNATRACE_ENVIRONMENT_URL']}/api/v2/events/ingest"
    request = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Api-Token {_get_token()}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if response.status != 201:
                raise RuntimeError(f"Dynatrace returned HTTP {response.status}")
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"Dynatrace returned HTTP {error.code}") from error

    return {"status": "forwarded", "event_type": event_type}
