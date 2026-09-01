import json
import urllib.request


def handler(event, context):
    url = "https://q0ufyci84l.execute-api.us-east-1.amazonaws.com/greetings"

    request = urllib.request.Request(url, method="GET")

    with urllib.request.urlopen(request, timeout=10) as response:
        if response.status != 200:
            raise Exception(f"Expected HTTP 200, got {response.status}")

        body = json.loads(response.read().decode("utf-8"))

        return {"statusCode": response.status, "body": json.dumbs(body)}
