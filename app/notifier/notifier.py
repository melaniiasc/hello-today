import json
from aws_lambda_powertools import Logger


logger = Logger(service="notifier")


@logger.inject_lambda_context
def handler(event, context):

    for record in event["Records"]:
        correlation_id = record["messageAttributes"]["correlation_id"]["stringValue"]
        logger.append_keys(correlation_id=correlation_id)
        logger.info("Notifier Lambda started")

        sns_message = json.loads(record["body"])

        logger.info(
            "Notification processed",
            extra={
                "event": "notification_processed",
                "date": sns_message["date"],
                "s3_key": sns_message["s3_key"],
            },
        )

    return {"statusCode": 200}