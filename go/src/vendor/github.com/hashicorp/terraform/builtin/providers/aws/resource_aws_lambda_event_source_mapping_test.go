package aws

import (
	"fmt"
	"regexp"
	"strconv"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSLambdaEventSourceMapping_basic(t *testing.T) {
	var conf lambda.EventSourceMappingConfiguration

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckLambdaEventSourceMappingDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSLambdaEventSourceMappingConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAwsLambdaEventSourceMappingExists("aws_lambda_event_source_mapping.lambda_event_source_mapping_test", &conf),
					testAccCheckAWSLambdaEventSourceMappingAttributes(&conf),
				),
			},
			resource.TestStep{
				Config: testAccAWSLambdaEventSourceMappingConfigUpdate,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAwsLambdaEventSourceMappingExists("aws_lambda_event_source_mapping.lambda_event_source_mapping_test", &conf),
					resource.TestCheckResourceAttr("aws_lambda_event_source_mapping.lambda_event_source_mapping_test",
						"batch_size",
						strconv.Itoa(200)),
					resource.TestCheckResourceAttr("aws_lambda_event_source_mapping.lambda_event_source_mapping_test",
						"enabled",
						strconv.FormatBool(false)),
					resource.TestMatchResourceAttr(
						"aws_lambda_event_source_mapping.lambda_event_source_mapping_test",
						"function_arn",
						regexp.MustCompile("example_lambda_name_update$"),
					),
				),
			},
		},
	})
}

func testAccCheckLambdaEventSourceMappingDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).lambdaconn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_lambda_event_source_mapping" {
			continue
		}

		_, err := conn.GetEventSourceMapping(&lambda.GetEventSourceMappingInput{
			UUID: aws.String(rs.Primary.ID),
		})

		if err == nil {
			return fmt.Errorf("Lambda event source mapping was not deleted")
		}

	}

	return nil

}

func testAccCheckAwsLambdaEventSourceMappingExists(n string, mapping *lambda.EventSourceMappingConfiguration) resource.TestCheckFunc {
	// Wait for IAM role
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Lambda event source mapping not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("Lambda event source mapping ID not set")
		}

		conn := testAccProvider.Meta().(*AWSClient).lambdaconn

		params := &lambda.GetEventSourceMappingInput{
			UUID: aws.String(rs.Primary.ID),
		}

		getSourceMappingConfiguration, err := conn.GetEventSourceMapping(params)
		if err != nil {
			return err
		}

		*mapping = *getSourceMappingConfiguration

		return nil
	}
}

func testAccCheckAWSLambdaEventSourceMappingAttributes(mapping *lambda.EventSourceMappingConfiguration) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		uuid := *mapping.UUID
		if uuid == "" {
			return fmt.Errorf("Could not read Lambda event source mapping's UUID")
		}

		return nil
	}
}

const testAccAWSLambdaEventSourceMappingConfig = `
resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy_for_role" {
    name = "policy_for_role"
    path = "/"
    description = "IAM policy for for Lamda event mapping testing"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
            "kinesis:ListStreams"
          ],
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy_attachment_for_role" {
    name = "policy_attachment_for_role"
    roles = ["${aws_iam_role.iam_for_lambda.name}"]
    policy_arn = "${aws_iam_policy.policy_for_role.arn}"
}

resource "aws_kinesis_stream" "kinesis_stream_test" {
    name = "kinesis_stream_test"
    shard_count = 1
}

resource "aws_lambda_function" "lambda_function_test_create" {
    filename = "test-fixtures/lambdatest.zip"
    function_name = "example_lambda_name_create"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "exports.example"
}

resource "aws_lambda_function" "lambda_function_test_update" {
    filename = "test-fixtures/lambdatest.zip"
    function_name = "example_lambda_name_update"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "exports.example"
}

resource "aws_lambda_event_source_mapping" "lambda_event_source_mapping_test" {
		batch_size = 100
		event_source_arn = "${aws_kinesis_stream.kinesis_stream_test.arn}"
		enabled = true
		depends_on = ["aws_iam_policy_attachment.policy_attachment_for_role"]
		function_name = "${aws_lambda_function.lambda_function_test_create.arn}"
		starting_position = "TRIM_HORIZON"
}
`

const testAccAWSLambdaEventSourceMappingConfigUpdate = `
resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy_for_role" {
    name = "policy_for_role"
    path = "/"
    description = "IAM policy for for Lamda event mapping testing"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
            "kinesis:ListStreams"
          ],
          "Resource": "*"
      }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy_attachment_for_role" {
    name = "policy_attachment_for_role"
    roles = ["${aws_iam_role.iam_for_lambda.name}"]
    policy_arn = "${aws_iam_policy.policy_for_role.arn}"
}

resource "aws_kinesis_stream" "kinesis_stream_test" {
    name = "kinesis_stream_test"
    shard_count = 1
}

resource "aws_lambda_function" "lambda_function_test_create" {
    filename = "test-fixtures/lambdatest.zip"
    function_name = "example_lambda_name_create"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "exports.example"
}

resource "aws_lambda_function" "lambda_function_test_update" {
    filename = "test-fixtures/lambdatest.zip"
    function_name = "example_lambda_name_update"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "exports.example"
}

resource "aws_lambda_event_source_mapping" "lambda_event_source_mapping_test" {
		batch_size = 200
		event_source_arn = "${aws_kinesis_stream.kinesis_stream_test.arn}"
		enabled = false
		depends_on = ["aws_iam_policy_attachment.policy_attachment_for_role"]
		function_name = "${aws_lambda_function.lambda_function_test_update.arn}"
		starting_position = "TRIM_HORIZON"
}
`
