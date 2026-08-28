import boto3
import json
import os
import uuid
from aws_lambda_powertools import Logger


TABLE_NAME = os.environ.get("TABLE_NAME")

logger = Logger(service="reader")


def get_table():
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    return dynamodb.Table(TABLE_NAME)


@logger.inject_lambda_context
def lambda_handler(event, context):
    correlation_id = str(uuid.uuid4())
    logger.append_keys(correlation_id=correlation_id)

    logger.info("Reader Lambda started")

    path_parameters = event.get("pathParameters")

    if path_parameters and "date" in path_parameters:
        return get_greeting_by_date(path_parameters["date"])

    return get_latest_greetings(event)


def get_latest_greetings(event):

    logger.info("Getting latest greetings")

    table = get_table()

    query_params = event.get("queryStringParameters") or {}

    limit = int(query_params.get("limit", 10))

    logger.info(
        "Scanning DynamoDB for latest greetings",
        extra={
            "table": TABLE_NAME,
            "limit": limit,
        },
    )

    response = table.scan()

    items = response.get("Items", [])

    items.sort(
        key=lambda x: x["created_at"],
        reverse=True,
    )

    logger.info(
        "Latest greetings retrieved",
        extra={
            "item_count": len(items),
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps(items[:limit]),
    }


def get_greeting_by_date(date):

    logger.info(
        "Getting greeting by date",
        extra={
            "date": date,
        },
    )

    table = get_table()

    response = table.get_item(Key={"greeting_date": date})

    item = response.get("Item")

    if not item:
        logger.info(
            "Greeting not found",
            extra={
                "date": date,
                "status_code": 404,
            },
        )

        return {
            "statusCode": 404,
            "body": json.dumps({"message": "Greeting not found"}),
        }

    logger.info(
        "Greeting found",
        extra={
            "date": date,
            "status_code": 200,
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps(item),
    }
