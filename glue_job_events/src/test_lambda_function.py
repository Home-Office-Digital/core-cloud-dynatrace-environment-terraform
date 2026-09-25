import importlib.util
import json
import os
import sys
import unittest
from pathlib import Path
from unittest import mock


class _SecretsClient:
    def get_secret_value(self, SecretId):
        if SecretId != "arn:aws:secretsmanager:eu-west-2:123456789012:secret:test":
            raise AssertionError("Unexpected secret ARN")
        return {"SecretString": json.dumps({"DYNATRACE_API_TOKEN": "test-token"})}


class _Boto3:
    @staticmethod
    def client(service_name):
        if service_name != "secretsmanager":
            raise AssertionError("Unexpected AWS client")
        return _SecretsClient()


class _Response:
    status = 201

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False


sys.modules["boto3"] = _Boto3()
spec = importlib.util.spec_from_file_location(
    "glue_event_handler", Path(__file__).with_name("lambda_function.py")
)
handler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(handler)


class LambdaHandlerTest(unittest.TestCase):
    def setUp(self):
        os.environ.update(
            {
                "ALERT_STATES": "START_REQUESTED,FAILED,TIMEOUT,STOPPED",
                "DYNATRACE_ENVIRONMENT_URL": "https://example.live.dynatrace.com",
                "EVENT_TIMEOUT_MINUTES": "15",
                "TOKEN_JSON_KEY": "DYNATRACE_API_TOKEN",
                "TOKEN_SECRET_ARN": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:test",
            }
        )
        handler._token = None

    @mock.patch.object(handler.urllib.request, "urlopen", return_value=_Response())
    def test_failed_job_creates_custom_alert(self, urlopen):
        result = handler.lambda_handler(
            {
                "id": "event-1",
                "account": "123456789012",
                "region": "eu-west-2",
                "detail-type": "Glue Job State Change",
                "detail": {
                    "jobName": "daily-etl",
                    "jobRunId": "jr_123",
                    "state": "FAILED",
                    "message": "Job failed",
                },
            },
            None,
        )

        request = urlopen.call_args.args[0]
        payload = json.loads(request.data)
        self.assertEqual(result["event_type"], "CUSTOM_ALERT")
        self.assertEqual(payload["properties"]["aws.glue.job.state"], "FAILED")
        self.assertEqual(payload["properties"]["aws.glue.job.run.id"], "jr_123")
        self.assertEqual(request.get_header("Authorization"), "Api-Token test-token")

    @mock.patch.object(handler.urllib.request, "urlopen", return_value=_Response())
    def test_start_job_run_creates_start_requested_alert(self, urlopen):
        handler.lambda_handler(
            {
                "id": "event-2",
                "account": "123456789012",
                "region": "eu-west-2",
                "detail-type": "AWS API Call via CloudTrail",
                "detail": {
                    "eventSource": "glue.amazonaws.com",
                    "eventName": "StartJobRun",
                    "requestParameters": {"jobName": "daily-etl"},
                    "responseElements": {"jobRunId": "jr_456"},
                },
            },
            None,
        )

        request = urlopen.call_args.args[0]
        payload = json.loads(request.data)
        self.assertEqual(payload["eventType"], "CUSTOM_ALERT")
        self.assertEqual(payload["properties"]["aws.glue.job.state"], "START_REQUESTED")
        self.assertEqual(payload["properties"]["aws.glue.job.run.id"], "jr_456")

    @mock.patch.object(handler.urllib.request, "urlopen")
    def test_failed_start_job_run_is_ignored(self, urlopen):
        result = handler.lambda_handler(
            {
                "detail-type": "AWS API Call via CloudTrail",
                "detail": {
                    "eventSource": "glue.amazonaws.com",
                    "eventName": "StartJobRun",
                    "errorCode": "EntityNotFoundException",
                    "errorMessage": "Failed to start job run due to missing metadata.",
                    "requestParameters": {"jobName": "missing-job"},
                },
            },
            None,
        )

        self.assertEqual(result, {"status": "ignored", "reason": "StartJobRun failed"})
        urlopen.assert_not_called()


if __name__ == "__main__":
    unittest.main()
