### RDS Restart - Version 1: targets specific db instances
### Works but throws error

import boto3

active_region = 'eu-west-2'

def lambda_handler(event, context):
    #Create boto3 connection to AWS
    rds_inst = boto3.client('rds', region_name=active_region)


    instanceOne='dev-postgres-internal-tableau-apps-notprod-dq'
    instanceTwo='ext-tableau-postgres-external-tableau-apps-notprod-dq'
    instanceThree='fms-postgres-fms-apps-notprod-dq'
    instanceFour='mds-postgres-dataingest-apps-notprod-dq'
    instanceFive='postgres-datafeeds-apps-notprod-dq'
    instanceSix='postgres-internal-tableau-apps-notprod-dq'
    instanceSeven='qa-postgres-internal-tableau-apps-notprod-dq'
    instanceEight='stg-postgres-internal-tableau-apps-notprod-dq'
    instanceNine='wip-postgres-tableau-apps-notprod-dq'


    print('RDS Instannces starting...')

    startup1=rds_inst.start_db_instance(DBInstanceIdentifier=instanceOne)
    startup2=rds_inst.start_db_instance(DBInstanceIdentifier=instanceTwo)
    startup3=rds_inst.start_db_instance(DBInstanceIdentifier=instanceThree)
    startup4=rds_inst.start_db_instance(DBInstanceIdentifier=instanceFour)
    startup5=rds_inst.start_db_instance(DBInstanceIdentifier=instanceFive)
    startup6=rds_inst.start_db_instance(DBInstanceIdentifier=instanceSix)
    startup7=rds_inst.start_db_instance(DBInstanceIdentifier=instanceSeven)
    startup8=rds_inst.start_db_instance(DBInstanceIdentifier=instanceEight)
    startup9=rds_inst.start_db_instance(DBInstanceIdentifier=instanceNine)



    print('RDS Instances Started')
