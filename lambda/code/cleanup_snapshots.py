"""
###############################################################################################
# This script looks for unencrypted snapshots in an AWS account and deletes them using boto3. #
# If the snapshot is in use by an AMI it will first be de-registered and then removed.        #
###############################################################################################
"""
# Import modules
import re
import boto3
import botocore

# Setup client
EC2 = boto3.client('ec2')

# Get snapshot list
RESPONSE = EC2.describe_snapshots(OwnerIds=['self'])
SNAPSHOT_LIST = RESPONSE['Snapshots']

# Create list used by function
LIST = []

# Iterate over the list of snapshots and store ones that are unencrypted
for r in SNAPSHOT_LIST:
    if r['Encrypted'] is False:
        print(r['SnapshotId'])
        LIST.append(r)
    else:
        continue

# Present the list to the user, and require input to continue.
ANSWER = input("Are you sure you want to delete the snapshots listed above?... (Y/n): ")

if ANSWER == "Y":
    for r in LIST:
        try:
            # Try to delete the snapshot
            EC2.delete_snapshot(SnapshotId=r['SnapshotId'])
        except botocore.exceptions.ClientError as error_msg:
            error = str(error_msg)
            # Search the error for the string below
            if 'is currently in use by' in error:
                try:
                    # Deregister the AMI
                    ami = re.search("(ami-.*)", error)
                    print("Deregistering AMI - " + ami.group(1))
                    EC2.deregister_image(ImageId=ami.group(1))
                except botocore.exceptions.ClientError as error_msg:
                    error = str(error_msg)
                    print(error)
                try:
                    # Delete the snapshot
                    print("Deleting snapshot...")
                    EC2.delete_snapshot(SnapshotId=r['SnapshotId'])
                    print(r['SnapshotId'] + " - " + "deleted.")
                except botocore.exceptions.ClientError as error_msg:
                    error = str(error_msg)
                    print(error)
            else:
                print(r['SnapshotId'] + " - " + error)
            continue
