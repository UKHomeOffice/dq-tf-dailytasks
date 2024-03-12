import re
import sys
import boto3

# Defines current active region

active_region = 'eu-west-2'
inst_to_exclude = []


def get_ssl_config_file_contents():
    """Extract contents of ssl config (notprod)"""
    s3 = boto3.resource('s3')
    try:
        s3_object = s3.Object(
            bucket_name='s3-dq-httpd-config-bucket-notprod',
            key='ssl.conf'
        )
        s3_response = s3_object.get()
        s3_object_body = s3_response.get('Body')
        content = s3_object_body.read().decode("utf-8")

    except s3.meta.client.exceptions.NoSuchBucket as err:
        print('No such bucket')
        print(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        print(str(err))
        return

    except s3.meta.client.exceptions.NoSuchKey as err:
        print('No such key')
        print(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        print(str(err))
        return

    except Exception as err:
        print('Unexpected exception')
        print(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        print(str(err))
        return

    else:
        ssl_lines = content.split("\n")

    finally:
        return ssl_lines


def get_inactive_notprod_instance_ip(ssl_lines):
    """
    Extract active ip address from contents of ssl config file
    Return the 'other' ip address for the inactive instance
    """
    if ssl_lines is None:
        return

    ip1 = "10.1.12.111"
    ip2 = "10.1.12.112"

    # Regex to extract one of the two notprod ip addresses
    # Whichever one is on a non-commented line is the 'active' one
    proxy_regex = re.compile(
        r"^\s*[^#]\s*ProxyPassReverse\s*/\s*http://(?P<active_ip>10\.1\.12\.11[12])/\s*$"
    )

    # Match active ip and return the 'other' one
    for line in ssl_lines:
        proxy_match = re.search(proxy_regex, line)
        if proxy_match:
            active_notprod_instance_ip = proxy_match.group("active_ip")
            if active_notprod_instance_ip == ip1:
                return ip2
            elif active_notprod_instance_ip == ip2:
                return ip1
            else:
                return

    return


def get_instance_name(instance):
    filtered_tags = [
        d.get("Value") for d in instance.tags if d.get("Key") == "Name"
    ]
    instance_name = filtered_tags[0]
    return instance_name


def lambda_handler(event, context):
    # Retrieve EC2 Instances
    notprod_instances = boto3.resource('ec2', region_name=active_region)

    # add 'inactive' notprod server to exclusion list
    ssl_lines = get_ssl_config_file_contents()
    inactive_notprod_instance_ip = get_inactive_notprod_instance_ip(ssl_lines)

    if inactive_notprod_instance_ip:
        for instance in notprod_instances.instances.filter(
                Filters=[{'Name': 'tag:Name',
                          'Values': ['ec2-internal-tableau-linux-apps-notprod-dq']},
                         {'Name': 'private-ip-address',
                          'Values': [inactive_notprod_instance_ip]}]):
            inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.filter(
            Filters=[{'Name': 'tag:Name',
                      'Values': ['*stag*']}]):
        inst_to_exclude.append(instance)

    # # this is commented out to start the Tab Deployment box
    # for instance in notprod_instances.instances.filter(
    # 	Filters =[{'Name':'tag:Name',
    # 			'Values': ['*deployment*']}]):
    #     inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.filter(
            Filters=[{'Name': 'tag:Name',
                      'Values': ['mock-ftp-server-centos']}]):
        inst_to_exclude.append(instance)

    for instance in notprod_instances.instances.filter(
            Filters=[{'Name': 'tag:Name',
                      'Values': ['FTP-server']}]):
        inst_to_exclude.append(instance)

    # Get only stopped instances
    stopped_instances = notprod_instances.instances.filter(
        Filters=[{'Name': 'instance-state-name',
                  'Values': ['stopped']}])

    # Iterate over all instances
    for instance in notprod_instances.instances.all():
        instance_name = get_instance_name(instance)
        print(f"Instance: {instance.id}  |  Name: {instance_name}")
        # Check if it's stopped and not in the exclusion list
        if instance in stopped_instances and instance not in inst_to_exclude:
            # Start the instance
            instance.start()
            print(f"Started : {instance.id}  |  Name: {instance_name}")
