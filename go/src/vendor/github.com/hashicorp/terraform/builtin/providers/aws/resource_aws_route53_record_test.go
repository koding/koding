package aws

import (
	"fmt"
	"strings"
	"testing"

	"github.com/hashicorp/terraform/helper/acctest"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/route53"
)

func TestCleanRecordName(t *testing.T) {
	cases := []struct {
		Input, Output string
	}{
		{"www.nonexample.com", "www.nonexample.com"},
		{"\\052.nonexample.com", "*.nonexample.com"},
		{"nonexample.com", "nonexample.com"},
	}

	for _, tc := range cases {
		actual := cleanRecordName(tc.Input)
		if actual != tc.Output {
			t.Fatalf("input: %s\noutput: %s", tc.Input, actual)
		}
	}
}

func TestExpandRecordName(t *testing.T) {
	cases := []struct {
		Input, Output string
	}{
		{"www", "www.nonexample.com"},
		{"dev.www", "dev.www.nonexample.com"},
		{"*", "*.nonexample.com"},
		{"nonexample.com", "nonexample.com"},
		{"test.nonexample.com", "test.nonexample.com"},
		{"test.nonexample.com.", "test.nonexample.com"},
	}

	zone_name := "nonexample.com"
	for _, tc := range cases {
		actual := expandRecordName(tc.Input, zone_name)
		if actual != tc.Output {
			t.Fatalf("input: %s\noutput: %s", tc.Input, actual)
		}
	}
}

func TestAccAWSRoute53Record_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.default",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_basic_fqdn(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.default",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfig_fqdn,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
				),
			},

			// Ensure that changing the name to include a trailing "dot" results in
			// nothing happening, because the name is stripped of trailing dots on
			// save. Otherwise, an update would occur and due to the
			// create_before_destroy, the record would actually be destroyed, and a
			// non-empty plan would appear, and the record will fail to exist in
			// testAccCheckRoute53RecordExists
			resource.TestStep{
				Config: testAccRoute53RecordConfig_fqdn_no_op,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_txtSupport(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:        func() { testAccPreCheck(t) },
		IDRefreshName:   "aws_route53_record.default",
		IDRefreshIgnore: []string{"zone_id"}, // just for this test
		Providers:       testAccProviders,
		CheckDestroy:    testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfigTXT,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_spfSupport(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.default",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfigSPF,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
					resource.TestCheckResourceAttr(
						"aws_route53_record.default", "records.2930149397", "include:notexample.com"),
				),
			},
		},
	})
}
func TestAccAWSRoute53Record_generatesSuffix(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.default",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfigSuffix,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_wildcard(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.wildcard",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53WildCardRecordConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.wildcard"),
				),
			},

			// Cause a change, which will trigger a refresh
			resource.TestStep{
				Config: testAccRoute53WildCardRecordConfigUpdate,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.wildcard"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_failover(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.www-primary",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53FailoverCNAMERecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.www-primary"),
					testAccCheckRoute53RecordExists("aws_route53_record.www-secondary"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_weighted_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.www-live",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53WeightedCNAMERecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.www-dev"),
					testAccCheckRoute53RecordExists("aws_route53_record.www-live"),
					testAccCheckRoute53RecordExists("aws_route53_record.www-off"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_alias(t *testing.T) {
	rs := acctest.RandString(10)
	config := fmt.Sprintf(testAccRoute53ElbAliasRecord, rs)
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.alias",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: config,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.alias"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_s3_alias(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53S3AliasRecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.alias"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_weighted_alias(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.elb_weighted_alias_live",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53WeightedElbAliasRecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.elb_weighted_alias_live"),
					testAccCheckRoute53RecordExists("aws_route53_record.elb_weighted_alias_dev"),
				),
			},

			resource.TestStep{
				Config: testAccRoute53WeightedR53AliasRecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.green_origin"),
					testAccCheckRoute53RecordExists("aws_route53_record.r53_weighted_alias_live"),
					testAccCheckRoute53RecordExists("aws_route53_record.blue_origin"),
					testAccCheckRoute53RecordExists("aws_route53_record.r53_weighted_alias_dev"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_geolocation_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53GeolocationCNAMERecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.default"),
					testAccCheckRoute53RecordExists("aws_route53_record.california"),
					testAccCheckRoute53RecordExists("aws_route53_record.oceania"),
					testAccCheckRoute53RecordExists("aws_route53_record.denmark"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_latency_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53LatencyCNAMERecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.us-east-1"),
					testAccCheckRoute53RecordExists("aws_route53_record.eu-west-1"),
					testAccCheckRoute53RecordExists("aws_route53_record.ap-northeast-1"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_TypeChange(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.sample",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordTypeChangePre,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.sample"),
				),
			},

			// Cause a change, which will trigger a refresh
			resource.TestStep{
				Config: testAccRoute53RecordTypeChangePost,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.sample"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_SetIdentiferChange(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.basic_to_weighted",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordSetIdentifierChangePre,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.basic_to_weighted"),
				),
			},

			// Cause a change, which will trigger a refresh
			resource.TestStep{
				Config: testAccRoute53RecordSetIdentifierChangePost,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.basic_to_weighted"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_AliasChange(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.elb_alias_change",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordAliasChangePre,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.elb_alias_change"),
				),
			},

			// Cause a change, which will trigger a refresh
			resource.TestStep{
				Config: testAccRoute53RecordAliasChangePost,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.elb_alias_change"),
				),
			},
		},
	})
}

func TestAccAWSRoute53Record_empty(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.empty",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfigEmptyName,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.empty"),
				),
			},
		},
	})
}

// Regression test for https://github.com/hashicorp/terraform/issues/8423
func TestAccAWSRoute53Record_longTXTrecord(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_route53_record.long_txt",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckRoute53RecordDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccRoute53RecordConfigLongTxtRecord,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckRoute53RecordExists("aws_route53_record.long_txt"),
				),
			},
		},
	})
}

func testAccCheckRoute53RecordDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).r53conn
	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_route53_record" {
			continue
		}

		parts := strings.Split(rs.Primary.ID, "_")
		zone := parts[0]
		name := parts[1]
		rType := parts[2]

		en := expandRecordName(name, "notexample.com")

		lopts := &route53.ListResourceRecordSetsInput{
			HostedZoneId:    aws.String(cleanZoneID(zone)),
			StartRecordName: aws.String(en),
			StartRecordType: aws.String(rType),
		}

		resp, err := conn.ListResourceRecordSets(lopts)
		if err != nil {
			if awsErr, ok := err.(awserr.Error); ok {
				// if NoSuchHostedZone, then all the things are destroyed
				if awsErr.Code() == "NoSuchHostedZone" {
					return nil
				}
			}
			return err
		}
		if len(resp.ResourceRecordSets) == 0 {
			return nil
		}
		rec := resp.ResourceRecordSets[0]
		if FQDN(*rec.Name) == FQDN(name) && *rec.Type == rType {
			return fmt.Errorf("Record still exists: %#v", rec)
		}
	}
	return nil
}

func testAccCheckRoute53RecordExists(n string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		conn := testAccProvider.Meta().(*AWSClient).r53conn
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No hosted zone ID is set")
		}

		parts := strings.Split(rs.Primary.ID, "_")
		zone := parts[0]
		name := parts[1]
		rType := parts[2]

		en := expandRecordName(name, "notexample.com")

		lopts := &route53.ListResourceRecordSetsInput{
			HostedZoneId:    aws.String(cleanZoneID(zone)),
			StartRecordName: aws.String(en),
			StartRecordType: aws.String(rType),
		}

		resp, err := conn.ListResourceRecordSets(lopts)
		if err != nil {
			return err
		}
		if len(resp.ResourceRecordSets) == 0 {
			return fmt.Errorf("Record does not exist")
		}

		// rec := resp.ResourceRecordSets[0]
		for _, rec := range resp.ResourceRecordSets {
			recName := cleanRecordName(*rec.Name)
			if FQDN(strings.ToLower(recName)) == FQDN(strings.ToLower(en)) && *rec.Type == rType {
				return nil
			}
		}
		return fmt.Errorf("Record does not exist: %#v", rs.Primary.ID)
	}
}

const testAccRoute53RecordConfig = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "www.NOTexamplE.com"
	type = "A"
	ttl = "30"
	records = ["127.0.0.1", "127.0.0.27"]
}
`

const testAccRoute53RecordConfigCNAMERecord = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "host123.domain"
	type = "CNAME"
	ttl = "30"
	records = ["1.2.3.4"]
}
`

const testAccRoute53RecordConfigCNAMERecordUpdateToCNAME = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "host123.domain"
	type = "A"
	ttl = "30"
	records = ["1.2.3.4"]
}
`

const testAccRoute53RecordConfig_fqdn = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "default" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "www.NOTexamplE.com"
  type    = "A"
  ttl     = "30"
  records = ["127.0.0.1", "127.0.0.27"]

  lifecycle {
    create_before_destroy = true
  }
}
`

const testAccRoute53RecordConfig_fqdn_no_op = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "default" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "www.NOTexamplE.com."
  type    = "A"
  ttl     = "30"
  records = ["127.0.0.1", "127.0.0.27"]

  lifecycle {
    create_before_destroy = true
  }
}
`

const testAccRoute53RecordNoConfig = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}
`

const testAccRoute53RecordConfigSuffix = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "subdomain"
	type = "A"
	ttl = "30"
	records = ["127.0.0.1", "127.0.0.27"]
}
`

const testAccRoute53WildCardRecordConfig = `
resource "aws_route53_zone" "main" {
    name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "subdomain"
	type = "A"
	ttl = "30"
	records = ["127.0.0.1", "127.0.0.27"]
}

resource "aws_route53_record" "wildcard" {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "*.notexample.com"
    type = "A"
    ttl = "30"
    records = ["127.0.0.1"]
}
`

const testAccRoute53WildCardRecordConfigUpdate = `
resource "aws_route53_zone" "main" {
    name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "subdomain"
	type = "A"
	ttl = "30"
	records = ["127.0.0.1", "127.0.0.27"]
}

resource "aws_route53_record" "wildcard" {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "*.notexample.com"
    type = "A"
    ttl = "60"
    records = ["127.0.0.1"]
}
`
const testAccRoute53RecordConfigTXT = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "/hostedzone/${aws_route53_zone.main.zone_id}"
	name = "subdomain"
	type = "TXT"
	ttl = "30"
	records = ["lalalala"]
}
`
const testAccRoute53RecordConfigSPF = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "default" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = "test"
	type = "SPF"
	ttl = "30"
	records = ["include:notexample.com"]
}
`

const testAccRoute53FailoverCNAMERecord = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_health_check" "foo" {
  fqdn = "dev.notexample.com"
  port = 80
  type = "HTTP"
  resource_path = "/"
  failure_threshold = "2"
  request_interval = "30"

  tags = {
    Name = "tf-test-health-check"
   }
}

resource "aws_route53_record" "www-primary" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = "${aws_route53_health_check.foo.id}"
  set_identifier = "www-primary"
  records = ["primary.notexample.com"]
}

resource "aws_route53_record" "www-secondary" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "www-secondary"
  records = ["secondary.notexample.com"]
}
`

const testAccRoute53WeightedCNAMERecord = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "www-dev" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  weighted_routing_policy {
	weight = 10
  }
  set_identifier = "dev"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "www-live" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  weighted_routing_policy {
	weight = 90
  }
  set_identifier = "live"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "www-off" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  weighted_routing_policy = {
	weight = 0
  }
  set_identifier = "off"
  records = ["dev.notexample.com"]
}
`

const testAccRoute53GeolocationCNAMERecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "default" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  geolocation_routing_policy {
    country = "*"
  }
  set_identifier = "Default"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "california" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  geolocation_routing_policy {
    country = "US"
    subdivision = "CA"
  }
  set_identifier = "California"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "oceania" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  geolocation_routing_policy {
    continent = "OC"
  }
  set_identifier = "Oceania"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "denmark" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  geolocation_routing_policy {
    country = "DK"
  }
  set_identifier = "Denmark"
  records = ["dev.notexample.com"]
}
`

const testAccRoute53LatencyCNAMERecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "us-east-1" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  latency_routing_policy {
    region = "us-east-1"
  }
  set_identifier = "us-east-1"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "eu-west-1" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  latency_routing_policy {
    region = "eu-west-1"
  }
  set_identifier = "eu-west-1"
  records = ["dev.notexample.com"]
}

resource "aws_route53_record" "ap-northeast-1" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"
  ttl = "5"
  latency_routing_policy {
    region = "ap-northeast-1"
  }
  set_identifier = "ap-northeast-1"
  records = ["dev.notexample.com"]
}
`

const testAccRoute53ElbAliasRecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "alias" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "A"

  alias {
  	zone_id = "${aws_elb.main.zone_id}"
  	name = "${aws_elb.main.dns_name}"
  	evaluate_target_health = true
  }
}

resource "aws_elb" "main" {
  name = "foobar-terraform-elb-%s"
  availability_zones = ["us-west-2a"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}
`

const testAccRoute53AliasRecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "origin" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "origin"
  type = "A"
  ttl = 5
  records = ["127.0.0.1"]
}

resource "aws_route53_record" "alias" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "A"

  alias {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "${aws_route53_record.origin.name}.${aws_route53_zone.main.name}"
    evaluate_target_health = true
  }
}
`

const testAccRoute53S3AliasRecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_s3_bucket" "website" {
  bucket = "website.notexample.com"
	acl = "public-read"
	website {
		index_document = "index.html"
	}
}

resource "aws_route53_record" "alias" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "A"

  alias {
    zone_id = "${aws_s3_bucket.website.hosted_zone_id}"
    name = "${aws_s3_bucket.website.website_domain}"
    evaluate_target_health = true
  }
}
`

const testAccRoute53WeightedElbAliasRecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_elb" "live" {
  name = "foobar-terraform-elb-live"
  availability_zones = ["us-west-2a"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_route53_record" "elb_weighted_alias_live" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "A"

  weighted_routing_policy {
	weight = 90
  }
  set_identifier = "live"

  alias {
    zone_id = "${aws_elb.live.zone_id}"
    name = "${aws_elb.live.dns_name}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "dev" {
  name = "foobar-terraform-elb-dev"
  availability_zones = ["us-west-2a"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_route53_record" "elb_weighted_alias_dev" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "A"

  weighted_routing_policy {
	weight = 10
  }
  set_identifier = "dev"

  alias {
    zone_id = "${aws_elb.dev.zone_id}"
    name = "${aws_elb.dev.dns_name}"
    evaluate_target_health = true
  }
}
`

const testAccRoute53WeightedR53AliasRecord = `
resource "aws_route53_zone" "main" {
  name = "notexample.com"
}

resource "aws_route53_record" "blue_origin" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "blue-origin"
  type = "CNAME"
  ttl = 5
  records = ["v1.terraform.io"]
}

resource "aws_route53_record" "r53_weighted_alias_live" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"

  weighted_routing_policy {
	weight = 90
  }
  set_identifier = "blue"

  alias {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "${aws_route53_record.blue_origin.name}.${aws_route53_zone.main.name}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "green_origin" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "green-origin"
  type = "CNAME"
  ttl = 5
  records = ["v2.terraform.io"]
}

resource "aws_route53_record" "r53_weighted_alias_dev" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "www"
  type = "CNAME"

  weighted_routing_policy {
	weight = 10
  }
  set_identifier = "green"

  alias {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "${aws_route53_record.green_origin.name}.${aws_route53_zone.main.name}"
    evaluate_target_health = false
  }
}
`

const testAccRoute53RecordTypeChangePre = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "sample" {
	zone_id = "${aws_route53_zone.main.zone_id}"
  name = "sample"
  type = "CNAME"
  ttl = "30"
  records = ["www.terraform.io"]
}
`

const testAccRoute53RecordTypeChangePost = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "sample" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "sample"
  type = "A"
  ttl = "30"
  records = ["127.0.0.1", "8.8.8.8"]
}
`

const testAccRoute53RecordSetIdentifierChangePre = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "basic_to_weighted" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "sample"
  type = "A"
  ttl = "30"
  records = ["127.0.0.1", "8.8.8.8"]
}
`

const testAccRoute53RecordSetIdentifierChangePost = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "basic_to_weighted" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "sample"
  type = "A"
  ttl = "30"
  records = ["127.0.0.1", "8.8.8.8"]
  set_identifier = "cluster-a"
  weighted_routing_policy {
    weight = 100
  }
}
`

const testAccRoute53RecordAliasChangePre = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_elb" "alias_change" {
  name = "foobar-tf-elb-alias-change"
  availability_zones = ["us-west-2a"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_route53_record" "elb_alias_change" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "alias-change"
  type = "A"

  alias {
    zone_id = "${aws_elb.alias_change.zone_id}"
    name = "${aws_elb.alias_change.dns_name}"
    evaluate_target_health = true
  }
}
`

const testAccRoute53RecordAliasChangePost = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "elb_alias_change" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name = "alias-change"
  type = "CNAME"
  ttl = "30"
  records = ["www.terraform.io"]
}
`

const testAccRoute53RecordConfigEmptyName = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "empty" {
	zone_id = "${aws_route53_zone.main.zone_id}"
	name = ""
	type = "A"
	ttl = "30"
	records = ["127.0.0.1"]
}
`

const testAccRoute53RecordConfigLongTxtRecord = `
resource "aws_route53_zone" "main" {
	name = "notexample.com"
}

resource "aws_route53_record" "long_txt" {
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "google.notexample.com"
    type = "TXT"
    ttl = "30"
    records = [
        "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiajKNMp\" \"/A12roF4p3MBm9QxQu6GDsBlWUWFx8EaS8TCo3Qe8Cj0kTag1JMjzCC1s6oM0a43JhO6mp6z/"
    ]
}
`
