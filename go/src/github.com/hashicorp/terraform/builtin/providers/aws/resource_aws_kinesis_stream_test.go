package aws

import (
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kinesis"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSKinesisStream_basic(t *testing.T) {
	var stream kinesis.StreamDescription

	config := fmt.Sprintf(testAccKinesisStreamConfig, rand.New(rand.NewSource(time.Now().UnixNano())).Int())

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckKinesisStreamDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: config,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckKinesisStreamExists("aws_kinesis_stream.test_stream", &stream),
					testAccCheckAWSKinesisStreamAttributes(&stream),
				),
			},
		},
	})
}

func TestAccAWSKinesisStream_retentionPeriod(t *testing.T) {
	var stream kinesis.StreamDescription

	ri := rand.New(rand.NewSource(time.Now().UnixNano())).Int()
	config := fmt.Sprintf(testAccKinesisStreamConfig, ri)
	updateConfig := fmt.Sprintf(testAccKinesisStreamConfigUpdateRetentionPeriod, ri)
	decreaseConfig := fmt.Sprintf(testAccKinesisStreamConfigDecreaseRetentionPeriod, ri)

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckKinesisStreamDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: config,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckKinesisStreamExists("aws_kinesis_stream.test_stream", &stream),
					testAccCheckAWSKinesisStreamAttributes(&stream),
					resource.TestCheckResourceAttr(
						"aws_kinesis_stream.test_stream", "retention_period", "24"),
				),
			},

			resource.TestStep{
				Config: updateConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckKinesisStreamExists("aws_kinesis_stream.test_stream", &stream),
					testAccCheckAWSKinesisStreamAttributes(&stream),
					resource.TestCheckResourceAttr(
						"aws_kinesis_stream.test_stream", "retention_period", "100"),
				),
			},

			resource.TestStep{
				Config: decreaseConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckKinesisStreamExists("aws_kinesis_stream.test_stream", &stream),
					testAccCheckAWSKinesisStreamAttributes(&stream),
					resource.TestCheckResourceAttr(
						"aws_kinesis_stream.test_stream", "retention_period", "28"),
				),
			},
		},
	})
}

func testAccCheckKinesisStreamExists(n string, stream *kinesis.StreamDescription) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No Kinesis ID is set")
		}

		conn := testAccProvider.Meta().(*AWSClient).kinesisconn
		describeOpts := &kinesis.DescribeStreamInput{
			StreamName: aws.String(rs.Primary.Attributes["name"]),
		}
		resp, err := conn.DescribeStream(describeOpts)
		if err != nil {
			return err
		}

		*stream = *resp.StreamDescription

		return nil
	}
}

func testAccCheckAWSKinesisStreamAttributes(stream *kinesis.StreamDescription) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if !strings.HasPrefix(*stream.StreamName, "terraform-kinesis-test") {
			return fmt.Errorf("Bad Stream name: %s", *stream.StreamName)
		}
		for _, rs := range s.RootModule().Resources {
			if rs.Type != "aws_kinesis_stream" {
				continue
			}
			if *stream.StreamARN != rs.Primary.Attributes["arn"] {
				return fmt.Errorf("Bad Stream ARN\n\t expected: %s\n\tgot: %s\n", rs.Primary.Attributes["arn"], *stream.StreamARN)
			}
			shard_count := strconv.Itoa(len(stream.Shards))
			if shard_count != rs.Primary.Attributes["shard_count"] {
				return fmt.Errorf("Bad Stream Shard Count\n\t expected: %s\n\tgot: %s\n", rs.Primary.Attributes["shard_count"], shard_count)
			}
		}
		return nil
	}
}

func testAccCheckKinesisStreamDestroy(s *terraform.State) error {
	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_kinesis_stream" {
			continue
		}
		conn := testAccProvider.Meta().(*AWSClient).kinesisconn
		describeOpts := &kinesis.DescribeStreamInput{
			StreamName: aws.String(rs.Primary.Attributes["name"]),
		}
		resp, err := conn.DescribeStream(describeOpts)
		if err == nil {
			if resp.StreamDescription != nil && *resp.StreamDescription.StreamStatus != "DELETING" {
				return fmt.Errorf("Error: Stream still exists")
			}
		}

		return nil

	}

	return nil
}

var testAccKinesisStreamConfig = `
resource "aws_kinesis_stream" "test_stream" {
	name = "terraform-kinesis-test-%d"
	shard_count = 2
	tags {
		Name = "tf-test"
	}
}
`

var testAccKinesisStreamConfigUpdateRetentionPeriod = `
resource "aws_kinesis_stream" "test_stream" {
	name = "terraform-kinesis-test-%d"
	shard_count = 2
	retention_period = 100
	tags {
		Name = "tf-test"
	}
}
`

var testAccKinesisStreamConfigDecreaseRetentionPeriod = `
resource "aws_kinesis_stream" "test_stream" {
	name = "terraform-kinesis-test-%d"
	shard_count = 2
	retention_period = 28
	tags {
		Name = "tf-test"
	}
}
`
