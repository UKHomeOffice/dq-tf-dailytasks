import os
import boto3


def _env(name, default=None):
    value = os.environ.get(name, default)
    if value is None or value == "":
        raise ValueError(f"Missing required environment variable: {name}")
    return value


def _csv_env(name, default=""):
    raw = os.environ.get(name, default)
    if not raw or not raw.strip():
        return []
    return [item.strip() for item in raw.split(",") if item.strip()]


def get_instance_name(instance):
    filtered_tags = [
        tag.get("Value") for tag in (instance.tags or []) if tag.get("Key") == "Name"
    ]
    return filtered_tags[0] if filtered_tags else instance.id


def lambda_handler(event, context):
    active_region = _env("ACTIVE_REGION", "eu-west-2")
    instance_names = _csv_env("INSTANCE_NAMES")

    if not instance_names:
        print("INSTANCE_NAMES is empty; nothing to start")
        return

    ec2 = boto3.resource("ec2", region_name=active_region)

    for name_tag in instance_names:
        for instance in ec2.instances.filter(
            Filters=[
                {"Name": "tag:Name", "Values": [name_tag]},
                {"Name": "instance-state-name", "Values": ["stopped"]},
            ]
        ):
            instance_name = get_instance_name(instance)
            instance.start()
            print(f"Started: {instance.id}  |  Name: {instance_name}")