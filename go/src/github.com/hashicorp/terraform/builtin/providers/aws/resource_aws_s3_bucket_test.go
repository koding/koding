package aws

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"reflect"
	"strconv"
	"testing"
	"time"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
)

func TestAccAWSS3Bucket_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSS3BucketDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSS3BucketConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "hosted_zone_id", HostedZoneIDForRegion("us-west-2")),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "region", "us-west-2"),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", ""),
				),
			},
		},
	})
}

func TestAccAWSS3Bucket_Policy(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSS3BucketDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSS3BucketConfigWithPolicy,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketPolicy(
						"aws_s3_bucket.bucket", testAccAWSS3BucketPolicy),
				),
			},
			resource.TestStep{
				Config: testAccAWSS3BucketConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketPolicy(
						"aws_s3_bucket.bucket", ""),
				),
			},
		},
	})
}

func TestAccAWSS3Bucket_Website(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSS3BucketDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSS3BucketWebsiteConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketWebsite(
						"aws_s3_bucket.bucket", "index.html", "", ""),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", testAccWebsiteEndpoint),
				),
			},
			resource.TestStep{
				Config: testAccAWSS3BucketWebsiteConfigWithError,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketWebsite(
						"aws_s3_bucket.bucket", "index.html", "error.html", ""),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", testAccWebsiteEndpoint),
				),
			},
			resource.TestStep{
				Config: testAccAWSS3BucketConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketWebsite(
						"aws_s3_bucket.bucket", "", "", ""),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", ""),
				),
			},
		},
	})
}

func TestAccAWSS3Bucket_WebsiteRedirect(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSS3BucketDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSS3BucketWebsiteConfigWithRedirect,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketWebsite(
						"aws_s3_bucket.bucket", "", "", "hashicorp.com"),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", testAccWebsiteEndpoint),
				),
			},
			resource.TestStep{
				Config: testAccAWSS3BucketConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSS3BucketExists("aws_s3_bucket.bucket"),
					testAccCheckAWSS3BucketWebsite(
						"aws_s3_bucket.bucket", "", "", ""),
					resource.TestCheckResourceAttr(
						"aws_s3_bucket.bucket", "website_endpoint", ""),
				),
			},
		},
	})
}

func testAccCheckAWSS3BucketDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).s3conn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_s3_bucket" {
			continue
		}
		_, err := conn.DeleteBucket(&s3.DeleteBucketInput{
			Bucket: aws.String(rs.Primary.ID),
		})
		if err != nil {
			return err
		}
	}
	return nil
}

func testAccCheckAWSS3BucketExists(n string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No S3 Bucket ID is set")
		}

		conn := testAccProvider.Meta().(*AWSClient).s3conn
		_, err := conn.HeadBucket(&s3.HeadBucketInput{
			Bucket: aws.String(rs.Primary.ID),
		})

		if err != nil {
			return fmt.Errorf("S3Bucket error: %v", err)
		}
		return nil
	}
}

func testAccCheckAWSS3BucketPolicy(n string, policy string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources[n]
		conn := testAccProvider.Meta().(*AWSClient).s3conn

		out, err := conn.GetBucketPolicy(&s3.GetBucketPolicyInput{
			Bucket: aws.String(rs.Primary.ID),
		})

		if err != nil {
			if policy == "" {
				// expected
				return nil
			} else {
				return fmt.Errorf("GetBucketPolicy error: %v, expected %s", err, policy)
			}
		}

		if v := out.Policy; v == nil {
			if policy != "" {
				return fmt.Errorf("bad policy, found nil, expected: %s", policy)
			}
		} else {
			expected := make(map[string]interface{})
			if err := json.Unmarshal([]byte(policy), &expected); err != nil {
				return err
			}
			actual := make(map[string]interface{})
			if err := json.Unmarshal([]byte(*v), &actual); err != nil {
				return err
			}

			if !reflect.DeepEqual(expected, actual) {
				return fmt.Errorf("bad policy, expected: %#v, got %#v", expected, actual)
			}
		}

		return nil
	}
}
func testAccCheckAWSS3BucketWebsite(n string, indexDoc string, errorDoc string, redirectTo string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, _ := s.RootModule().Resources[n]
		conn := testAccProvider.Meta().(*AWSClient).s3conn

		out, err := conn.GetBucketWebsite(&s3.GetBucketWebsiteInput{
			Bucket: aws.String(rs.Primary.ID),
		})

		if err != nil {
			if indexDoc == "" {
				// If we want to assert that the website is not there, than
				// this error is expected
				return nil
			} else {
				return fmt.Errorf("S3BucketWebsite error: %v", err)
			}
		}

		if v := out.IndexDocument; v == nil {
			if indexDoc != "" {
				return fmt.Errorf("bad index doc, found nil, expected: %s", indexDoc)
			}
		} else {
			if *v.Suffix != indexDoc {
				return fmt.Errorf("bad index doc, expected: %s, got %#v", indexDoc, out.IndexDocument)
			}
		}

		if v := out.ErrorDocument; v == nil {
			if errorDoc != "" {
				return fmt.Errorf("bad error doc, found nil, expected: %s", errorDoc)
			}
		} else {
			if *v.Key != errorDoc {
				return fmt.Errorf("bad error doc, expected: %s, got %#v", errorDoc, out.ErrorDocument)
			}
		}

		if v := out.RedirectAllRequestsTo; v == nil {
			if redirectTo != "" {
				return fmt.Errorf("bad redirect to, found nil, expected: %s", redirectTo)
			}
		} else {
			if *v.HostName != redirectTo {
				return fmt.Errorf("bad redirect to, expected: %s, got %#v", redirectTo, out.RedirectAllRequestsTo)
			}
		}

		return nil
	}
}

// These need a bit of randomness as the name can only be used once globally
// within AWS
var randInt = rand.New(rand.NewSource(time.Now().UnixNano())).Int()
var testAccWebsiteEndpoint = fmt.Sprintf("tf-test-bucket-%d.s3-website-us-west-2.amazonaws.com", randInt)
var testAccAWSS3BucketPolicy = fmt.Sprintf(`{ "Version": "2008-10-17", "Statement": [ { "Sid": "", "Effect": "Allow", "Principal": { "AWS": "*" }, "Action": "s3:GetObject", "Resource": "arn:aws:s3:::tf-test-bucket-%d/*" } ] }`, randInt)

var testAccAWSS3BucketConfig = fmt.Sprintf(`
resource "aws_s3_bucket" "bucket" {
	bucket = "tf-test-bucket-%d"
	acl = "public-read"
}
`, randInt)

var testAccAWSS3BucketWebsiteConfig = fmt.Sprintf(`
resource "aws_s3_bucket" "bucket" {
	bucket = "tf-test-bucket-%d"
	acl = "public-read"

	website {
		index_document = "index.html"
	}
}
`, randInt)

var testAccAWSS3BucketWebsiteConfigWithError = fmt.Sprintf(`
resource "aws_s3_bucket" "bucket" {
	bucket = "tf-test-bucket-%d"
	acl = "public-read"

	website {
		index_document = "index.html"
		error_document = "error.html"
	}
}
`, randInt)

var testAccAWSS3BucketWebsiteConfigWithRedirect = fmt.Sprintf(`
resource "aws_s3_bucket" "bucket" {
	bucket = "tf-test-bucket-%d"
	acl = "public-read"

	website {
		redirect_all_requests_to = "hashicorp.com"
	}
}
`, randInt)

var testAccAWSS3BucketConfigWithPolicy = fmt.Sprintf(`
resource "aws_s3_bucket" "bucket" {
	bucket = "tf-test-bucket-%d"
	acl = "public-read"
	policy = %s
}
`, randInt, strconv.Quote(testAccAWSS3BucketPolicy))
