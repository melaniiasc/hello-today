import boto3

from app.handler import lambda_handler
from moto import mock_aws


BUCKET_NAME = "hello-today-bucket"
TABLE_NAME = "hello-today-table"


@mock_aws
def test_lambda_handler_uploads_file_to_s3_and_writes_to_dynamodb():

    s3 = boto3.client("s3", region_name="us-east-1")

    s3.create_bucket(Bucket=BUCKET_NAME)

    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

    table = dynamodb.create_table(
        TableName=TABLE_NAME,
        KeySchema=[{"AttributeName": "greeting_date", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "greeting_date", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    table.wait_until_exists()

    response = lambda_handler({}, {})

    assert response["statusCode"] == 200

    objects = s3.list_objects_v2(Bucket=BUCKET_NAME)

    assert "Contents" in objects
    assert len(objects["Contents"]) == 1

    key = objects["Contents"][0]["Key"]

    file = s3.get_object(Bucket=BUCKET_NAME, Key=key)

    content = file["Body"].read().decode()

    assert content.startswith("Hello, today is")

    response = table.scan()

    items = response["Items"]

    assert len(items) == 1

    item = items[0]

    assert "greeting_date" in item
    assert "message" in item
    assert "s3_key" in item
    assert "created_at" in item

    assert item["s3_key"] == key
    assert item["message"].startswith("Hello, today is")
