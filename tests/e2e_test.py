# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
# import relevant modules
import unittest
from runner import Runner

# Creates a class derived form unittest.TestCase

class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """
            provider "aws" {
              region = "eu-west-2"
             #profile = "foo"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "dailytasks" {
              source = "./mymodule"
              providers = {aws = "aws"}

            path_module = "./mymodule"
            namespace     = "preprod"
            naming_suffix = "apps-preprod-dq"
            cidr_block                      = "10.1.0.0/16"
            public_subnet_cidr_block        = "10.1.0.0/24"
            ad_subnet_cidr_block            = "10.1.0.0/24"
            az                              = "eu-west-2a"
            az2                             = "eu-west-2b"
            adminpassword                   = "1234"
            ad_aws_ssm_document_name        = "1234"
            ad_writer_instance_profile_name = "1234"
            haproxy_private_ip              = "1.2.3.3"
            haproxy_private_ip2             = "1.2.3.4"
              }
        """
        self.result = Runner(self.snippet).result

    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test_name_suffix_aws_lambda_function_rdsshutdown_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds-shutdown-function"]["tags.Name"], "rds_shutdown-apps-preprod-dq")

    def test_name_suffix_aws_iam_role_rds_shutdown_role_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_iam_role.rds-shutdown_role"]["tags.Name"], "rds-shutdown_role-apps-preprod-dq")

    def test_name_suffix_aws_lambda_function_rdsstartup_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds_startup-function"]["tags.Name"], "rds_daily_startup-apps-preprod-dq")

    def test_name_suffix_aws_iam_role_rds_startup_role_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_iam_role.rds_startup_role"]["tags.Name"], "rds_startup_role-apps-preprod-dq")

    def test_name_suffix_aws_lambda_function_ec2startup_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.ec2-startup-function"]["tags.Name"], "ec2_daily_startup-apps-preprod-dq")

    def test_name_suffix_aws_iam_role_ec2_startup_role_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_iam_role.ec2_startup_role"]["tags.Name"], "ec2_startup_role-apps-preprod-dq")

    def test_name_suffix_aws_lambda_function_ec2shutdown_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_lambda_function.ec2-shutdown-function"]["tags.Name"], "ec2_daily_shutdown-apps-preprod-dq")

    def test_name_suffix_aws_iam_role_ec2_shutdown_role_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_iam_role.ec2_shutdown_role"]["tags.Name"], "ec2_shutdown_role-apps-preprod-dq")

if __name__ == '__main__':
    unittest.main()

