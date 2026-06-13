import boto3
import yaml
from datetime import datetime, timezone

# Load config
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

DAYS_OLD = config['days_old']
EXCLUDE_TAG = config['exclude_tag']

ec2 = boto3.client('ec2')


def get_old_instances():

    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            }
        ]
    )

    old_instances = []

    for reservation in response['Reservations']:

        for instance in reservation['Instances']:

            instance_id = instance['InstanceId']
            launch_time = instance['LaunchTime']

            age = (
                datetime.now(timezone.utc) - launch_time
            ).days

            tags = {
                tag['Key']: tag['Value']
                for tag in instance.get('Tags', [])
            }

            if tags.get(EXCLUDE_TAG) == "True":
                continue

            if age > DAYS_OLD:
                old_instances.append(instance_id)

    return old_instances


def stop_instances(instances):

    if instances:
        ec2.stop_instances(
            InstanceIds=instances
        )

        print(f"Stopped instances: {instances}")


if __name__ == "__main__":

    instances = get_old_instances()

    stop_instances(instances)
