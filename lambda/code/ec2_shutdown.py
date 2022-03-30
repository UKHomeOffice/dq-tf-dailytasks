import boto3

# Defines current active region

active_region = 'eu-west-2'
inst_to_exclude = []


def lambda_handler(event, context):

    # Retrieve EC2 Instances
    notprod_instances = boto3.resource('ec2', region_name=active_region)
    for instance in notprod_instances.instances.all():

        print("Instance-ID: ", instance.id)

        #Get only running instances
        running_instances = notprod_instances.instances.filter(
            Filters=[{'Name': 'instance-state-name',
                      'Values': ['running']}])

        # # temp, disable shiutdown of ec2-dev-tableau-ops-notprod-dq?
        # for instance in notprod_instances.instances.filter(
        #     Filters =[{'Name':'tag:Name',
        #            'Values': ['ec2-dev-tableau-ops-notprod-dq']}]):
        #     inst_to_exclude.append(instance)
        #
        # for instance in notprod_instances.instances.filter(
        #     Filters =[{'Name':'tag:Name',
        #            'Values': ['bastion-linux-ops-notprod-dq']}]):
        #     inst_to_exclude.append(instance)
        #
        for instance in notprod_instances.instances.filter(
            Filters =[{'Name':'tag:Name',
                   'Values': ['ec2-haproxy-peering-notprod-dq']}]):
            inst_to_exclude.append(instance)

        for instance in notprod_instances.instances.filter(
            Filters =[{'Name':'tag:Name',
                   'Values': ['bastion-win-ops-notprod-dq']}]):
            inst_to_exclude.append(instance)
        #
        # for instance in notprod_instances.instances.filter(
        #     Filters =[{'Name':'tag:Name',
        #            'Values': ['ec2-internal-tableau-linux-apps-notprod-dq']}]):
        #     inst_to_exclude.append(instance)

        # Stop the instances
        for instance in running_instances:
            if instance not in inst_to_exclude:
                instance.stop()
                print('Stopped instance: ', instance.id)
