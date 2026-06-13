from app import get_old_instances
from app import stop_instances


def lambda_handler(event, context):

    instances = get_old_instances()

    stop_instances(instances)

    return {
        "statusCode": 200,
        "body": f"Stopped instances: {instances}"
    }
