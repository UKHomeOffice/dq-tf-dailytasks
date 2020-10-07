import boto3
import fnmatch

# Defines current active region

active_region = 'eu-west-2'
inst_to_exclude = []
dbs_running = []
stage_inst_list = ['*stag*']
rds_list = ['stag*', 'stg*']

def send_message_to_slack(text):
    """
    Formats the text provides and posts to a specific Slack web app's URL

    Args:
        text : the message to be displayed on the Slack channel

    Returns:
        Slack API repsonse
    """


    try:
        post = {"text": "{0}".format(text)}

        ssm_param_name = 'slack_notification_webhook'
        ssm = boto3.client('ssm', config=CONFIG)
        try:
            response = ssm.get_parameter(Name=ssm_param_name, WithDecryption=True)
        except ClientError as err:
            if err.response['Error']['Code'] == 'ParameterNotFound':
                LOGGER.info('Slack SSM parameter %s not found. No notification \
                   sent', ssm_param_name)
            else:
                LOGGER.error("Unexpected error when attempting to get Slack webhook URL: %s", err)
                return
        if 'Value' in response['Parameter']:
            url = response['Parameter']['Value']

            json_data = json.dumps(post)
            req = urllib.request.Request(
                url,
                data=json_data.encode('ascii'),
                headers={'Content-Type': 'application/json'})
            LOGGER.info('Sending notification to Slack')
            response = urllib.request.urlopen(req)

        else:
            LOGGER.info('Value for Slack SSM parameter %s not found. No notification \
               sent', ssm_param_name)
            return

    except Exception as err:
        LOGGER.error(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        LOGGER.error(str(err))

def list_of_stage_ec2(inst):
    """

    This function generates a list
    of Staging EC2 instances

    Returns a list of EC2 inst with Stag in its name

    """
    for instance in prod_instances.instances.filter(
    	Filters =[{'Name':'tag:Name',
    			'Values': [inst]}]):
        inst_to_exclude.append(instance)

def lambda_handler(event, context):

    """
    This functions finds out which EC2 and RDS instances
    with Stage in its name that are in 'running'
    or 'available' state

    this functons sends Slack notification if the above
    conidtion is met

    """

    # Retrieve EC2 Instances
    prod_instances = boto3.resource('ec2', region_name=active_region)

    for i in stage_inst_list:
        list_of_stage_ec2(i)

    running_instances = prod_instances.instances.filter(
        Filters=[{'Name': 'instance-state-name',
                  'Values': ['running']}])

    for instance in running_instances:
        if instance in inst_to_exclude:
            for tag in instance.tags:
                if 'Name' in tag['Key']:
                    instance_name = tag['Value']
            send_message_to_slack('The EC2 Instance {0} is currently Turned on... '.format(instance))

    # Retrieve RDS Instances
    RDS = boto3.client('rds')

    rds_instances = RDS.describe_db_instances()
    for rds_instance in rds_instances['DBInstances']:
        if rds_instance['DBInstanceStatus'] == "available":
            dbs_running.append(rds_instance['DBInstanceIdentifier'])

    for i in rds_list:
        for j in dbs_running:
            if fnmatch.fnmatch(j, i):
                send_message_to_slack('The RDS Instance {0} is currently Turned on... '.format(j))
