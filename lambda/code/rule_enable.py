import boto3
import os

def lambda_handler(event, context):
    event_client = boto3.client('events')
    rule_names = os.getenv('RULE_NAMES').split(',')

    for rule in rule_names:
        try:
            event_client.enable_rule(Name=rule)
            print(f"Successfully enabled rule: {rule}")
        except Exception as e:
            print(f"Failed to enable rule {rule}: {e}")