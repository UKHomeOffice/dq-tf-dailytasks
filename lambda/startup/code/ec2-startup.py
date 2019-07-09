import boto3

# Defines current active region

active_region = 'eu-west-2'


def lambda_handler(event, context):

# Retrieve EC2 Instances
    notprod_instances = boto3.resource('ec2', region_name=active_region)
    for instance in notprod_instances.instances.all():
        
        print("Instance-ID: ", instance.id)
        
        #Get only stopped instances
        stopped_instances = notprod_instances.instances.filter(
            Filters=[{'Name': 'instance-state-name',
                      'Values': ['stopped']}])

        # Start the instances
        for instance in stopped_instances:
            instance.start()
            print('Started instance: ', instance.id)
