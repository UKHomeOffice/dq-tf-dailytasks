import boto3
import fnmatch

RDS = boto3.client('rds')
def lambda_handler(event, context):

    # Check that our inputs are valid
    try:
        instances = event.get('instances')
        action = event.get('action')
    except Exception as e:
        return "Exception! Failed with: {0}".format(e)

    if (not (action == "stop" or action == "start")) or (not isinstance(instances, list)):
        return "instances must be a list of strings, action must be \"start\" or \"stop\""

    # Filter through our databases, only get the instances that are featured in our instances list
    dbs = set([])
    rds_instances = RDS.describe_db_instances()
    for rds_instance in rds_instances['DBInstances']:
        for instance in instances:
            if instance in rds_instance['DBInstanceIdentifier']:
                dbs.add(rds_instance['DBInstanceIdentifier'])

# Discard stg, dev, and qa RDS instances from start up
    dbs_to_stop = dbs.copy()
    for db in dbs:
        if fnmatch.fnmatch(db, "stg*"):
            dbs_to_stop.discard(db)
        if fnmatch.fnmatch(db, "dev*"):
            dbs_to_stop.discard(db)
        if fnmatch.fnmatch(db, "qa*"):
            dbs_to_stop.discard(db)

    # Apply our action
    for db in dbs_to_stop:
        try:
            if action == "start":

                response = RDS.start_db_instance(DBInstanceIdentifier=db)
            else:
                response = RDS.stop_db_instance(DBInstanceIdentifier=db)

            print("{0} status: {1}".format(db, response['DBInstanceStatus']))
        except Exception as e:
            print('RDS already in a stopped state: '+ (rds_instance['DBInstanceIdentifier']))

    return "Completed!"
