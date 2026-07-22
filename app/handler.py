import json
import boto3
from datetime import datetime

s3 = boto3.client("s3")
BUCKET_NAME = "hello-today-bucket"

def lambda_handler(event, context):

    today = datetime.utcnow().strftime("%Y-%m-%d")
    key = f"hello-current-day/hello-{today}.txt"
    body = f"Hello, today is {today}"

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=body
    )

    return {
        "statusCode": 200,
        "body": body
    }