import boto3

# Defines current active region

active_region = 'eu-west-2'
inst_to_exclude = []

def lambda_handler(event, context):

    # Retrieve EC2 Instances
    notprod_instances = boto3.resource('ec2', region_name=active_region)

    for instance in notprod_instances.instances.filter(
    	Filters =[{'Name':'tag:Name',
    			'Values': ['*stag*']}]):
        inst_to_exclude.append(instance)

    # # this is commented out to start the Tab Deployment box
    # for instance in notprod_instances.instances.filter(
    # 	Filters =[{'Name':'tag:Name',
    # 			'Values': ['*deployment*']}]):
    #     inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.filter(
    	Filters =[{'Name':'tag:Name',
    			'Values': ['mock-ftp-server-centos']}]):
        inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.filter(
    	Filters =[{'Name':'tag:Name',
    			'Values': ['FTP-server']}]):
        inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.all():
        print("Instance-ID: ", instance.id)

        #Get only stopped instances
        stopped_instances = notprod_instances.instances.filter(
            Filters=[{'Name': 'instance-state-name',
                      'Values': ['stopped']}])

        # Start the instances
        for instance in stopped_instances:
            if instance not in inst_to_exclude:
                instance.start()
                print('Started instance: ', instance.id)
