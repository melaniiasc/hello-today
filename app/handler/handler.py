import datetime

import boto3
import os
import json
import uuid
from aws_lambda_powertools import Logger

BUCKET_NAME = os.environ.get("BUCKET_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

s3 = boto3.client("s3", region_name="us-east-1")
dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
sns = boto3.client("sns", region_name="us-east-1")
table = dynamodb.Table(TABLE_NAME)

logger = Logger(service="writer")


@logger.inject_lambda_context
def lambda_handler(event, context):
    correlation_id = str(uuid.uuid4())
    logger.append_keys(correlation_id=correlation_id)

    logger.info("Writer Lambda started")

    today = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%d")
    key = f"hello-current-day/hello-{today}.txt"
    body = f"Hello, today is {today}"

    logger.info(
        "Preparing greeting",
        extra={
            "today": today,
            "key": key,
        },
    )

    s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=body)
    logger.info(
        "Greeting successfully written to S3",
        extra={
            "bucket": BUCKET_NAME,
            "key": key,
        },
    )

    table.put_item(
        Item={
            "greeting_date": today,
            "message": body,
            "s3_key": key,
            "created_at": today,
        }
    )
    logger.info(
        "Greeting successfully written to DynamoDB",
        extra={
            "table": TABLE_NAME,
            "greeting_date": today,
        },
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({"date": today, "message": body, "s3_key": key}),
        MessageAttributes={
            "correlation_id": {
                "DataType": "String",
                "StringValue": correlation_id,
            }
        },
    )

    logger.info(
        "Notification successfully published to SNS",
        extra={
            "topic_arn": SNS_TOPIC_ARN,
        },
    )

    logger.info("Writer Lambda finished successfully")

    return {"statusCode": 200, "body": body}
