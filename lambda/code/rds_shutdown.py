import boto3
RDS = boto3.client('rds')
def lambda_handler(event, context):

    # Check that our inputs are valid
    try:
        instances = event.get('instances')
        action = event.get('action')
    except Exception as e:
        return "Exception! Failed with: {0}".format(e)

    if (not (action == "stop" or action == "start")):
        return "Action must be \"start\" or \"stop\""

    # Filter through our databases, only get the instances that are featured in our instances list
    dbs = set([])
    rds_instances = RDS.describe_db_instances()
    for rds_instance in rds_instances['DBInstances']:
        dbs.add(rds_instance['DBInstanceIdentifier'])

    # Apply our action
    for db in dbs:
        try:
            if action == "start":
                response = RDS.start_db_instance(DBInstanceIdentifier=db)
            else:
                response = RDS.stop_db_instance(DBInstanceIdentifier=db)

            print("{0} status: {1}".format(db, response['DBInstanceStatus']))
        except Exception as e:
            print('RDS already in a stopped state: '+ db)

    return "Completed!"
