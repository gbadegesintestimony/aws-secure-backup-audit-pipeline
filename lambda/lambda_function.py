"""Reconstructed example based on the Karatu assessment's Python starter.

The user's document confirms the Lambda/S3 trigger and CloudWatch execution,
but did not contain an exported, editable Lambda source file.
"""
import urllib.parse

import boto3

table = boto3.resource("dynamodb").Table("backup-log")


def lambda_handler(event, context):
    for record in event["Records"]:
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        table.put_item(
            Item={
                "backup_id": key,
                "size_bytes": record["s3"]["object"]["size"],
                "uploaded_at": record["eventTime"],
                "bucket": record["s3"]["bucket"]["name"],
            }
        )
        print(f"Audit record created for: {key}")
    return {"statusCode": 200}
