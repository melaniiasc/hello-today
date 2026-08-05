import datetime

import boto3
import os
import json

BUCKET_NAME = os.environ.get("BUCKET_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

s3 = boto3.client("s3", region_name="us-east-1")
dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
sns = boto3.client("sns", region_name="us-east-1")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):

    today = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%d")
    key = f"hello-current-day/hello-{today}.txt"
    body = f"Hello, today is {today}"

    s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=body)
    table.put_item(
        Item={
            "greeting_date": today,
            "message": body,
            "s3_key": key,
            "created_at": today,
        }
    )
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({"date": today, "message": body, "s3_key": key}),
    )

    return {"statusCode": 200, "body": body}
