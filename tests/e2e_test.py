# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
import unittest
from runner import Runner

# Creates a class derived form unittest.TestCase

class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """
            provider "aws" {
              region = "eu-west-2"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "dailytasks" {
              source = "./mymodule"

              providers = {
                aws = "aws"
              }
               
              path_module          =   "unset"
              az2                  =   "eu-west-2b"
              namespace            =   "notprod"
              naming_suffix        =   "motprod-dq"
            }
        """
        self.result = Runner(self.snippet).result
    
    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test_aws_lambda_function_ec2startup_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.ec2-startup-function"]["tags.Name"], "ec2_daily_startup")
    
    def test_aws_lambda_function_ec2shutdown_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.ec2-shutdown-function"]["tags.Name"], "ec2_daily_shutdown")
   
    def test_aws_lambda_function_rdsshutdown_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds-shutdown-function"]["tags.Name"], "rds_daily_shutdown")
 
    def test_aws_lambda_function_rdsstartup_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds-startup-function"]["tags.Name"], "rds_daily_startup")

    def test_iam_lambda_ec2_shutdown_role_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role.ec2_shutdown_testrole"]["tags.Name"], "ec2_shutdown_testrole")

    def test_iam_lambda_ec2_startup_role_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role.ec2_startup_role"]["tags.Name"], "ec2_startup-role")
    
    def test_iam_lambda_rds_shutdown_role_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role.rds-shutdown_role"]["tags.Name"], "rds-shutdown_role")
   
    def test_iam_lambda_rds_startup_role_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role.rds_startup_role"]["tags.Name"], "rds_startup_role")
    
    def test_iam_policy_document_logs_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy_document.eventwatch_logs_doc"]["tags.Name"], "eventwatch_logs_doc")

    def test_iam_policy_document_ec2_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy_document.eventwatch_ec2_doc"]["tags.Name"], "eventwatch_ec2_doc")

    def test_iam_policy_document_rds_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy_document.eventwatch_rds_doc"]["tags.Name"], "eventwatch_rds_doc")

    def test_iam_policy_logs_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy.eventwatch_logs_policy"]["tags.Name"], "eventwatch_logs_policy")

    def test_iam_policy_ec2_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy.eventwatch_ec2_policy"]["tags.Name"], "eventwatch_ec2_policy")

    def test_iam_policy_rds_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_policy.eventwatch_rds_policy"]["tags.Name"], "eventwatch_rds_policy")

    def test_iam_role_policy_attachment_logs_tag(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role_policy_attachment.eventwatch_logs_policy_attachment"]["tags.Name"], "eventwatch_logs_policy_attachment")

    def test_iam_role_policy_attachment_ec2_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role_policy_attachment.eventwatch_ec2_policy_attachment"]["tags.Name"], "eventwatch_ec2_policy_attachment")

    def test_iam_role_policy_attachment_rds_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_iam_role_policy_attachment.eventwatch_rds_policy_attachment"]["tags.Name"], "eventwatch_rds_policy_attachment")

    def test_cloudwatch_ec2shut_event_rule(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_rule.daily_ec2_shutdown"]["tags.Name"], "daily_ec2_shutdown")

    def test_cloudwatch_ec2start_event_rule(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_rule.daily_ec2_startup"]["tags.Name"], "daily_ec2_startup")

    def test_cloudwatch_rdsshut_event_rule(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_rule.daily_rds-shutdown"]["tags.Name"], "daily_rds-shutdown")    

    def test_cloudwatch_rdsstart__event_rule(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_rule.daily_rds-startup"]["tags.Name"], "daily_rds-startup")
    
   
    def test_cloudwatch_event_ec2target(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_target.ec2_lambda_target"]["tags.Name"], "ec2_lambda_target")

    def test_cloudwatch_event_rdstarget(self):
        self.assertEqual(self.result['dailytasks']["aws_cloudwatch_event_target.rds_lambda_target"]["tags.Name"], "rds_lambda_target")

if __name__ == '__main__':
    unittest.main()
