import boto3
import os

def lambda_handler(event, context):
    event_client = boto3.client('events')
    rule_names = os.getenv('RULE_NAMES').split(',')

    for rule in rule_names:
        try:
            event_client.disable_rule(Name=rule)
            print(f"Successfully disabled rule: {rule}")
        except Exception as e:
            print(f"Failed to disable rule {rule}: {e}")