import json
import logging


logger = logging.getLogger()
logger.setLevel("INFO")


def handler(event, context):

    for record in event["Records"]:

        body = json.loads(record["body"])

        sns_message = json.loads(body["Message"])

        logger.info(
            {
                "event": "notification_processed",
                "date": sns_message["date"],
                "s3_key": sns_message["s3_key"],
            }
        )

    return {"statusCode": 200}
