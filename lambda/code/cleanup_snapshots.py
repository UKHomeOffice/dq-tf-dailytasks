# pylint: disable=broad-except
""" This script looks for unencrypted snapshots
    in an AWS account and deletes them using boto3.
    If the snapshot is in use by an AMI it will first
    be de-registered and then removed.
"""

import sys
import logging
import boto3
import botocore
from botocore.config import Config

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
LOG_GROUP_NAME = None
LOG_STREAM_NAME = None

CONFIG = Config(
    retries=dict(
        max_attempts=20
    )
)

def lambda_handler(event , context):
    # Setup client
    ec2 = boto3.client('ec2')

    # Get snapshot list
    response = ec2.describe_snapshots(OwnerIds=['self'])
    snapshot_list = response['Snapshots']

    # Create list used by function
    list = []

    # Iterate over the list of snapshots and store ones that are unencrypted
    for res in snapshot_list:
        if res['Encrypted'] == False:
            print(res['SnapshotId'])
            list.append(res)
        else:
            continue

        for res in list:
            try:
                # Try to delete the snapshot
                ec2.delete_snapshot(SnapshotId=res['SnapshotId'])
            except Exception as err:
                error_handler(sys.exc_info()[2].tb_lineno, err)
                # Search the error for the string below
                if 'is currently in use by' in error:
                    try:
                        # Deregister the AMI
                        ami = re.search("(ami-.*)", error)
                        print("Deregistering AMI - " + ami.group(1))
                        ec2.deregister_image(ImageId=ami.group(1))
                    except Exception as err:
                        error_handler(sys.exc_info()[2].tb_lineno, err)
                    try:
                        # Delete the snapshot
                        print("Deleting snapshot...")
                        ec2.delete_snapshot(SnapshotId=res['SnapshotId'])
                        print(res['SnapshotId'] + " - " + "deleted.")
                    except Exception as err:
                        error_handler(sys.exc_info()[2].tb_lineno, err)
                else:
                    print(res['SnapshotId'] + " - " + error)
                continue


def lambda_handler(event , context):
    # Setup client
    ec2 = boto3.client('ec2')

    # Get snapshot list
    response = ec2.describe_snapshots(OwnerIds=['self'])
    snapshot_list = response['Snapshots']

    # Create list used by function
    list = []

    # Iterate over the list of snapshots and store ones that are unencrypted
    for res in snapshot_list:
        if res['Encrypted'] == False:
            print(res['SnapshotId'])
            list.append(res)
        else:
            continue

    # Present the list to the user, and require input to continue.

        for res in list:
            try:
                # Try to delete the snapshot
                ec2.delete_snapshot(SnapshotId=res['SnapshotId'])
            except Exception as err:
                error_handler(sys.exc_info()[2].tb_lineno, err)
                # Search the error for the string below
                if 'is currently in use by' in error:
                    try:
                        # Deregister the AMI
                        ami = re.search("(ami-.*)", error)
                        print("Deregistering AMI - " + ami.group(1))
                        ec2.deregister_image(ImageId=ami.group(1))
                    except Exception as err:
                        error_handler(sys.exc_info()[2].tb_lineno, err)
                    try:
                        # Delete the snapshot
                        print("Deleting snapshot...")
                        ec2.delete_snapshot(SnapshotId=res['SnapshotId'])
                        print(res['SnapshotId'] + " - " + "deleted.")
                    except Exception as err:
                        error_handler(sys.exc_info()[2].tb_lineno, err)
                else:
                    print(res['SnapshotId'] + " - " + error)
                continue
