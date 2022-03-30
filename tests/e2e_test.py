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
              profile = "foo"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "dailytasks" {
              source = "./mymodule"
              providers = {aws = aws}

              path_module = "./"
              namespace     = "notprod"
              naming_suffix = "notprod-dq"
            }
        """
        self.runner = Runner(self.snippet)
        self.result = self.runner.result

    def test_name_suffix_aws_lambda_function_rds_shutdown_tags(self):
          self.assertEqual(self.runner.get_value("module.dailytasks.aws_lambda_function.rds_shutdown[0]", "tags"), {"Name": "rds-shutdown-notprod-dq"})

    def test_name_suffix_aws_iam_role_rds_shutdown_role_tags(self):
          self.assertEqual(self.runner.get_value("module.dailytasks.aws_iam_role.rds_shutdown[0]", "tags"), {"Name": "rds-shutdown-notprod-dq"})

    def test_name_suffix_aws_lambda_function_rds_startup_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_lambda_function.rds_startup[0]", "tags"), {"Name": "rds-startup-notprod-dq"})

    def test_name_suffix_aws_iam_role_rds_startup_role_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_iam_role.rds_startup[0]", "tags"), {"Name": "rds-startup-notprod-dq"})

    def test_name_suffix_aws_lambda_function_ec2_startup_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_lambda_function.ec2_startup[0]", "tags"), {"Name": "ec2-startup-notprod-dq"})

    def test_name_suffix_aws_lambda_function_ec2_shutdown_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_lambda_function.ec2_shutdown[0]", "tags"), {"Name": "ec2-shutdown-notprod-dq"})

    def test_name_suffix_aws_iam_role_ec2_shutdown_role_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_iam_role.ec2_shutdown[0]", "tags"), {"Name": "ec2-shutdown-notprod-dq"})

    def test_name_suffix_aws_iam_role_ec2_startup_role_tags(self):
            self.assertEqual(self.runner.get_value("module.dailytasks.aws_iam_role.ec2_startup[0]", "tags"), {"Name": "ec2-startup-notprod-dq"})

    def test_name_suffix_aws_lambda_function_cleanup_snapshots_tags(self):
          self.assertEqual(self.runner.get_value("module.dailytasks.aws_lambda_function.cleanup_snapshots", "tags"), {"Name": "cleanup-ec2-snapshots-notprod-dq"})

    def test_name_suffix_aws_iam_role_cleanup_snapshots_role_tags(self):
          self.assertEqual(self.runner.get_value("module.dailytasks.aws_iam_role.cleanup_snapshots", "tags"), {"Name": "cleanup-ec2-snapshots-notprod-dq"})

if __name__ == '__main__':
    unittest.main()
