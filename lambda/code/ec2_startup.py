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
        content_list = content.split("\n")

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
        return content_list

    finally:
        return


def get_inactive_notprod_instance_ip(ssl_lines):
    """Extract ip address from ssl config file"""
    if ssl_lines is None:
        return

    proxy_regex = re.compile(
        r"^\s*[^#]\s*ProxyPassReverse\s*/\s*http://(?P<inactive_ip>10\.1\.12\.11[12])/\s*$"
    )

    for line in ssl_lines:
        proxy_match = re.search(proxy_regex, line)
        if proxy_match:
            inactive_notprod_instance_ip = proxy_match.group("inactive_ip")
            return inactive_notprod_instance_ip

    return


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
                          'Values': inactive_notprod_instance_ip}]):
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

    for instance in notprod_instances.instances.all():
        print("Instance-ID: ", instance.id)

        # Get only stopped instances
        stopped_instances = notprod_instances.instances.filter(
            Filters=[{'Name': 'instance-state-name',
                      'Values': ['stopped']}])

        # Start the instances
        for instance in stopped_instances:
            if instance not in inst_to_exclude:
                instance.start()
                print('Started instance: ', instance.id)
