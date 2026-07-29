import boto3
import json


TABLE_NAME = "hello-today-table"


def lambda_handler(event, context):

    dynamodb = boto3.resource("dynamodb", "us-east-1")
    table = dynamodb.Table(TABLE_NAME)
    path_parameters = event.get("pathParameters")

    if path_parameters and "date" in path_parameters:
        return get_greeting_by_date(path_parameters["date"])

    return get_latest_greetings(event)


def get_latest_greetings(event):

    query_params = event.get("queryStringParameters") or {}

    limit = int(query_params.get("limit", 10))

    response = table.scan()

    items = response.get("Items", [])

    items.sort(key=lambda x: x["created_at"], reverse=True)

    return {"statusCode": 200, "body": json.dumps(items[:limit])}


def get_greeting_by_date(date):

    response = table.get_item(Key={"greeting_date": date})

    item = response.get("Item")

    if not item:
        return {
            "statusCode": 404,
            "body": json.dumps({"message": "Greeting not found"}),
        }

    return {"statusCode": 200, "body": json.dumps(item)}
