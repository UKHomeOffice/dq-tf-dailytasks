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

            module "dailytasks" {
              source = "./mymodule"
              providers = {aws = "aws"}

            path_module = "./"
            namespace     = "preprod"
            naming_suffix = "apps-preprod-dq"
              }
        """
        self.result = Runner(self.snippet).result

    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test_aws_lambda_function_rdsshutdown_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds-shutdown-function"]["tags.Name"], "rds_shutdown-apps-preprod-dq")


if __name__ == '__main__':
    unittest.main()

