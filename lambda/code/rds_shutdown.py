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
    instanceFour='postgres-datafeeds-apps-notprod-dq'
    instanceFive='postgres-internal-tableau-apps-notprod-dq'
    instanceSix='qa-postgres-internal-tableau-apps-notprod-dq'
    instanceSeven='mds-rds-mssql2012-dataingest-apps-notprod-dq'


    print('RDS Instannces stopping...')
    
    shutdown1=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceOne)
    shutdown2=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceTwo)
    shutdown3=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceThree)
    shutdown4=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceFour)
    shutdown5=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceFive)
    shutdown6=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceSix)
    shutdown7=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceSeven)



    print('RDS Instances Stopped')
