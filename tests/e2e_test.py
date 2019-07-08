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
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "root_modules" {
              source = "./mymodule"
              providers = {aws = "aws"}

            path_module = "./"
            naming_suffix = "apps-preprod-dq"
            namespace     = "preprod"
              }
        """
        self.result = Runner(self.snippet).result

    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test__name_suffix_aws_lambda_function_rds_shutdown_tags(self):
        self.assertEqual(self.result['root_modules']["aws_lambda_function.rds-shutdown-function"]["tags.Name"], "rds_shutdown-apps-preprod-dq")

    def test_iam_lambda_rds_shutdown_role_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_role.rds-shutdown_role"]["tags.Name"], "rds-shutdown_role")

    def test_iam_policy_document_logs_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_policy_document.eventwatch_logs_doc"]["tags.Name"], "eventwatch_logs_doc")

    def test_iam_policy_document_rds_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_policy_document.eventwatch_rds_doc"]["tags.Name"], "eventwatch_rds_doc")

    def test_iam_policy_logs_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_policy.eventwatch_logs_policy"]["tags.Name"], "eventwatch_logs_policy")

    def test_iam_policy_rds_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_policy.eventwatch_rds_policy"]["tags.Name"], "eventwatch_rds_policy")

    def test_iam_role_policy_attachment_logs_tag(self):
        self.assertEqual(self.result['root_modules']["aws_iam_role_policy_attachment.eventwatch_logs_policy_attachment"]["tags.Name"], "eventwatch_logs_policy_attachment")

    def test_iam_role_policy_attachment_rds_tags(self):
        self.assertEqual(self.result['root_modules']["aws_iam_role_policy_attachment.eventwatch_rds_policy_attachment"]["tags.Name"], "eventwatch_rds_policy_attachment")

    def test_cloudwatch_rdsshut_event_rule(self):
        self.assertEqual(self.result['root_modules']["aws_cloudwatch_event_rule.daily_rds-shutdown"]["tags.Name"], "daily_rds-shutdown")

    def test_cloudwatch_event_rdstarget(self):
        self.assertEqual(self.result['root_modules']["aws_cloudwatch_event_target.rds_lambda_target"]["tags.Name"], "rds_lambda_target")

if __name__ == '__main__':
    unittest.main()
