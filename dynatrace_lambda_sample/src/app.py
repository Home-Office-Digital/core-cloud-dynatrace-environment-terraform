import json


def handler(event, context):
    response = {
        "message": "Dynatrace OneAgent Lambda sample invoked",
        "request_id": context.aws_request_id,
    }
    print(json.dumps({"event": "sample_invocation", **response}))
    return {"statusCode": 200, "body": json.dumps(response)}