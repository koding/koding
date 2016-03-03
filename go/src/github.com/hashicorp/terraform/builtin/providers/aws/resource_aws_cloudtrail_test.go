package aws

import (
	"fmt"
	"log"
	"math/rand"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudtrail"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSCloudTrail_basic(t *testing.T) {
	var trail cloudtrail.Trail

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCloudTrailDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "include_global_service_events", "true"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfigModified,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "s3_key_prefix", "/prefix"),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "include_global_service_events", "false"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
		},
	})
}

func TestAccAWSCloudTrail_enable_logging(t *testing.T) {
	var trail cloudtrail.Trail

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCloudTrailDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					// AWS will create the trail with logging turned off.
					// Test that "enable_logging" default works.
					testAccCheckCloudTrailLoggingEnabled("aws_cloudtrail.foobar", true, &trail),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfigModified,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					testAccCheckCloudTrailLoggingEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					testAccCheckCloudTrailLoggingEnabled("aws_cloudtrail.foobar", true, &trail),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
		},
	})
}

func TestAccAWSCloudTrail_is_multi_region(t *testing.T) {
	var trail cloudtrail.Trail

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCloudTrailDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "is_multi_region_trail", "false"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfigMultiRegion,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "is_multi_region_trail", "true"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "is_multi_region_trail", "false"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
		},
	})
}

func TestAccAWSCloudTrail_logValidation(t *testing.T) {
	var trail cloudtrail.Trail

	// TODO: Add test for KMS Key ID
	// once https://github.com/hashicorp/terraform/pull/3928 is merged
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCloudTrailDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig_logValidation,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "s3_key_prefix", ""),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "include_global_service_events", "true"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", true, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig_logValidationModified,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "s3_key_prefix", ""),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "include_global_service_events", "true"),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
		},
	})
}

func TestAccAWSCloudTrail_tags(t *testing.T) {
	var trail cloudtrail.Trail
	var trailTags []*cloudtrail.Tag
	var trailTagsModified []*cloudtrail.Tag

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCloudTrailDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig_tags,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "tags.#", "2"),
					testAccCheckCloudTrailLoadTags(&trail, &trailTags),
					testAccCheckCloudTrailCheckTags(&trailTags, map[string]string{"Foo": "moo", "Pooh": "hi"}),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig_tagsModified,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "tags.#", "3"),
					testAccCheckCloudTrailLoadTags(&trail, &trailTagsModified),
					testAccCheckCloudTrailCheckTags(&trailTagsModified, map[string]string{"Foo": "moo", "Moo": "boom", "Pooh": "hi"}),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
			resource.TestStep{
				Config: testAccAWSCloudTrailConfig_tagsModifiedAgain,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckCloudTrailExists("aws_cloudtrail.foobar", &trail),
					resource.TestCheckResourceAttr("aws_cloudtrail.foobar", "tags.#", "0"),
					testAccCheckCloudTrailLoadTags(&trail, &trailTagsModified),
					testAccCheckCloudTrailCheckTags(&trailTagsModified, map[string]string{}),
					testAccCheckCloudTrailLogValidationEnabled("aws_cloudtrail.foobar", false, &trail),
					testAccCheckCloudTrailKmsKeyIdEquals("aws_cloudtrail.foobar", "", &trail),
				),
			},
		},
	})
}

func testAccCheckCloudTrailExists(n string, trail *cloudtrail.Trail) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		conn := testAccProvider.Meta().(*AWSClient).cloudtrailconn
		params := cloudtrail.DescribeTrailsInput{
			TrailNameList: []*string{aws.String(rs.Primary.ID)},
		}
		resp, err := conn.DescribeTrails(&params)
		if err != nil {
			return err
		}
		if len(resp.TrailList) == 0 {
			return fmt.Errorf("Trail not found")
		}
		*trail = *resp.TrailList[0]

		return nil
	}
}

func testAccCheckCloudTrailLoggingEnabled(n string, desired bool, trail *cloudtrail.Trail) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		conn := testAccProvider.Meta().(*AWSClient).cloudtrailconn
		params := cloudtrail.GetTrailStatusInput{
			Name: aws.String(rs.Primary.ID),
		}
		resp, err := conn.GetTrailStatus(&params)

		if err != nil {
			return err
		}
		if *resp.IsLogging != desired {
			return fmt.Errorf("Expected logging status %t, given %t", desired, *resp.IsLogging)
		}

		return nil
	}
}

func testAccCheckCloudTrailLogValidationEnabled(n string, desired bool, trail *cloudtrail.Trail) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if trail.LogFileValidationEnabled == nil {
			return fmt.Errorf("No LogFileValidationEnabled attribute present in trail: %s", trail)
		}

		if *trail.LogFileValidationEnabled != desired {
			return fmt.Errorf("Expected log validation status %t, given %t", desired,
				*trail.LogFileValidationEnabled)
		}

		// local state comparison
		enabled, ok := rs.Primary.Attributes["enable_log_file_validation"]
		if !ok {
			return fmt.Errorf("No enable_log_file_validation attribute defined for %s, expected %t",
				n, desired)
		}
		desiredInString := fmt.Sprintf("%t", desired)
		if enabled != desiredInString {
			return fmt.Errorf("Expected log validation status %s, saved %s", desiredInString, enabled)
		}

		return nil
	}
}

func testAccCheckCloudTrailKmsKeyIdEquals(n string, desired string, trail *cloudtrail.Trail) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if desired != "" && trail.KmsKeyId == nil {
			return fmt.Errorf("No KmsKeyId attribute present in trail: %s, expected %s",
				trail, desired)
		}

		// work around string pointer
		var kmsKeyIdInString string
		if trail.KmsKeyId == nil {
			kmsKeyIdInString = ""
		} else {
			kmsKeyIdInString = *trail.KmsKeyId
		}

		if kmsKeyIdInString != desired {
			return fmt.Errorf("Expected KMS Key ID %q to equal %q",
				*trail.KmsKeyId, desired)
		}

		kmsKeyId, ok := rs.Primary.Attributes["kms_key_id"]
		if desired != "" && !ok {
			return fmt.Errorf("No kms_key_id attribute defined for %s", n)
		}
		if kmsKeyId != desired {
			return fmt.Errorf("Expected KMS Key ID %q, saved %q", desired, kmsKeyId)
		}

		return nil
	}
}

func testAccCheckAWSCloudTrailDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).cloudtrailconn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_cloudtrail" {
			continue
		}

		params := cloudtrail.DescribeTrailsInput{
			TrailNameList: []*string{aws.String(rs.Primary.ID)},
		}

		resp, err := conn.DescribeTrails(&params)

		if err == nil {
			if len(resp.TrailList) != 0 &&
				*resp.TrailList[0].Name == rs.Primary.ID {
				return fmt.Errorf("CloudTrail still exists: %s", rs.Primary.ID)
			}
		}
	}

	return nil
}

func testAccCheckCloudTrailLoadTags(trail *cloudtrail.Trail, tags *[]*cloudtrail.Tag) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		conn := testAccProvider.Meta().(*AWSClient).cloudtrailconn
		input := cloudtrail.ListTagsInput{
			ResourceIdList: []*string{trail.TrailARN},
		}
		out, err := conn.ListTags(&input)
		if err != nil {
			return err
		}
		log.Printf("[DEBUG] Received CloudTrail tags during test: %s", out)
		if len(out.ResourceTagList) > 0 {
			*tags = out.ResourceTagList[0].TagsList
		}
		log.Printf("[DEBUG] Loading CloudTrail tags into a var: %s", *tags)
		return nil
	}
}

var cloudTrailRandInt = rand.New(rand.NewSource(time.Now().UnixNano())).Int()

var testAccAWSCloudTrailConfig = fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
    name = "tf-trail-foobar"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)

var testAccAWSCloudTrailConfigModified = fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
    name = "tf-trail-foobar"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
    s3_key_prefix = "/prefix"
    include_global_service_events = false
    enable_logging = false
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)

var testAccAWSCloudTrailConfigMultiRegion = fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
    name = "tf-trail-foobar"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
    is_multi_region_trail = true
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)

var testAccAWSCloudTrailConfig_logValidation = fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
    name = "tf-acc-trail-log-validation-test"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
    is_multi_region_trail = true
    include_global_service_events = true
    enable_log_file_validation = true
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)

var testAccAWSCloudTrailConfig_logValidationModified = fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
    name = "tf-acc-trail-log-validation-test"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
    include_global_service_events = true
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)

var testAccAWSCloudTrailConfig_tags_tpl = `
resource "aws_cloudtrail" "foobar" {
    name = "tf-acc-trail-log-validation-test"
    s3_bucket_name = "${aws_s3_bucket.foo.id}"
    %s
}

resource "aws_s3_bucket" "foo" {
	bucket = "tf-test-trail-%d"
	force_destroy = true
	policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AWSCloudTrailAclCheck",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::tf-test-trail-%d"
		},
		{
			"Sid": "AWSCloudTrailWrite",
			"Effect": "Allow",
			"Principal": "*",
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::tf-test-trail-%d/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		}
	]
}
POLICY
}
`

var testAccAWSCloudTrailConfig_tags = fmt.Sprintf(testAccAWSCloudTrailConfig_tags_tpl,
	`tags {
		Foo = "moo"
		Pooh = "hi"
	}`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)
var testAccAWSCloudTrailConfig_tagsModified = fmt.Sprintf(testAccAWSCloudTrailConfig_tags_tpl,
	`tags {
		Foo = "moo"
		Pooh = "hi"
		Moo = "boom"
	}`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)
var testAccAWSCloudTrailConfig_tagsModifiedAgain = fmt.Sprintf(testAccAWSCloudTrailConfig_tags_tpl,
	"", cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)
