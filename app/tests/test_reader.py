import boto3
import json

from moto import mock_aws
import os

os.environ["TABLE_NAME"] = "test-table"

from app.reader.reader import lambda_handler


TABLE_NAME = os.environ.get("TABLE_NAME")


@mock_aws
def test_get_latest_greetings():

    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    table = dynamodb.create_table(
        TableName=TABLE_NAME,
        KeySchema=[{"AttributeName": "greeting_date", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "greeting_date", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    table.wait_until_exists()

    table.put_item(
        Item={
            "greeting_date": "2026-07-27",
            "message": "Hello, today is 2026-07-27",
            "s3_key": "hello-2026-07-27.txt",
            "created_at": "2026-07-27T10:00:00",
        }
    )

    table.put_item(
        Item={
            "greeting_date": "2026-07-29",
            "message": "Hello, today is 2026-07-29",
            "s3_key": "hello-2026-07-29.txt",
            "created_at": "2026-07-29T10:00:00",
        }
    )

    response = lambda_handler({"queryStringParameters": {"limit": "10"}}, {})

    assert response["statusCode"] == 200

    body = json.loads(response["body"])

    assert len(body) == 2

    # newest first
    assert body[0]["greeting_date"] == "2026-07-29"
    assert body[1]["greeting_date"] == "2026-07-27"


@mock_aws
def test_get_greeting_by_date():

    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    table = dynamodb.create_table(
        TableName=TABLE_NAME,
        KeySchema=[{"AttributeName": "greeting_date", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "greeting_date", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    table.wait_until_exists()

    table.put_item(
        Item={
            "greeting_date": "2026-07-29",
            "message": "Hello, today is 2026-07-29",
            "s3_key": "hello-2026-07-29.txt",
            "created_at": "2026-07-29T10:00:00",
        }
    )

    response = lambda_handler({"pathParameters": {"date": "2026-07-29"}}, {})

    assert response["statusCode"] == 200

    body = json.loads(response["body"])

    assert body["greeting_date"] == "2026-07-29"
    assert body["message"] == "Hello, today is 2026-07-29"


@mock_aws
def test_get_greeting_returns_404_if_not_found():

    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    table = dynamodb.create_table(
        TableName=TABLE_NAME,
        KeySchema=[{"AttributeName": "greeting_date", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "greeting_date", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    table.wait_until_exists()

    response = lambda_handler({"pathParameters": {"date": "2026-01-01"}}, {})

    assert response["statusCode"] == 404

    body = json.loads(response["body"])

    assert body["message"] == "Greeting not found"
