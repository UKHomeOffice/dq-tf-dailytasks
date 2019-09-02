# Creates manual snapshots of RDS Instances

import boto3
import datetime
import time

def lambda_handler(event, context):
#connecting to rds client interface
    rds = boto3.client('rds')

#creates place holder for instances to be backed up
    instances_to_backup = []
    response = rds.describe_db_instances()

    instances = response['DBInstances']
    print("The total number of instances to be processed is %s " % len(instances))

    for instance in instances:
        engine = instance['Engine']
        instances_to_backup.append(instance['DBInstanceIdentifier'])

        print("This instance - %s has engine - %s " % (instance['DBInstanceIdentifier'], engine))
    print("RDS snapshot backups stated at %s...\n" % datetime.datetime.now())
    for bkup in instances_to_backup:
        today = datetime.date.today()
        rds.create_db_snapshot(
            DBInstanceIdentifier = bkup,
            DBSnapshotIdentifier = "{}-{:%Y-%m-%d}".format(bkup,today),
