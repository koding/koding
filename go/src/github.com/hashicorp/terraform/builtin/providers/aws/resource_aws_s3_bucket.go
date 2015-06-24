package aws

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hashicorp/terraform/helper/schema"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
)

func resourceAwsS3Bucket() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsS3BucketCreate,
		Read:   resourceAwsS3BucketRead,
		Update: resourceAwsS3BucketUpdate,
		Delete: resourceAwsS3BucketDelete,

		Schema: map[string]*schema.Schema{
			"bucket": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"acl": &schema.Schema{
				Type:     schema.TypeString,
				Default:  "private",
				Optional: true,
				ForceNew: true,
			},

			"policy": &schema.Schema{
				Type:      schema.TypeString,
				Optional:  true,
				StateFunc: normalizeJson,
			},

			"website": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"index_document": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},

						"error_document": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},

						"redirect_all_requests_to": &schema.Schema{
							Type: schema.TypeString,
							ConflictsWith: []string{
								"website.0.index_document",
								"website.0.error_document",
							},
							Optional: true,
						},
					},
				},
			},

			"hosted_zone_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"region": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"website_endpoint": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"tags": tagsSchema(),

			"force_destroy": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
			},
		},
	}
}

func resourceAwsS3BucketCreate(d *schema.ResourceData, meta interface{}) error {
	s3conn := meta.(*AWSClient).s3conn
	awsRegion := meta.(*AWSClient).region

	// Get the bucket and acl
	bucket := d.Get("bucket").(string)
	acl := d.Get("acl").(string)

	log.Printf("[DEBUG] S3 bucket create: %s, ACL: %s", bucket, acl)

	req := &s3.CreateBucketInput{
		Bucket: aws.String(bucket),
		ACL:    aws.String(acl),
	}

	// Special case us-east-1 region and do not set the LocationConstraint.
	// See "Request Elements: http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUT.html
	if awsRegion != "us-east-1" {
		req.CreateBucketConfiguration = &s3.CreateBucketConfiguration{
			LocationConstraint: aws.String(awsRegion),
		}
	}

	_, err := s3conn.CreateBucket(req)
	if err != nil {
		return fmt.Errorf("Error creating S3 bucket: %s", err)
	}

	// Assign the bucket name as the resource ID
	d.SetId(bucket)

	return resourceAwsS3BucketUpdate(d, meta)
}

func resourceAwsS3BucketUpdate(d *schema.ResourceData, meta interface{}) error {
	s3conn := meta.(*AWSClient).s3conn
	if err := setTagsS3(s3conn, d); err != nil {
		return err
	}

	if d.HasChange("policy") {
		if err := resourceAwsS3BucketPolicyUpdate(s3conn, d); err != nil {
			return err
		}
	}

	if d.HasChange("website") {
		if err := resourceAwsS3BucketWebsiteUpdate(s3conn, d); err != nil {
			return err
		}
	}

	return resourceAwsS3BucketRead(d, meta)
}

func resourceAwsS3BucketRead(d *schema.ResourceData, meta interface{}) error {
	s3conn := meta.(*AWSClient).s3conn

	var err error
	_, err = s3conn.HeadBucket(&s3.HeadBucketInput{
		Bucket: aws.String(d.Id()),
	})
	if err != nil {
		if awsError, ok := err.(awserr.RequestFailure); ok && awsError.StatusCode() == 404 {
			d.SetId("")
		} else {
			// some of the AWS SDK's errors can be empty strings, so let's add
			// some additional context.
			return fmt.Errorf("error reading S3 bucket \"%s\": %s", d.Id(), err)
		}
	}

	// Read the policy
	pol, err := s3conn.GetBucketPolicy(&s3.GetBucketPolicyInput{
		Bucket: aws.String(d.Id()),
	})
	log.Printf("[DEBUG] S3 bucket: %s, read policy: %v", d.Id(), pol)
	if err != nil {
		if err := d.Set("policy", ""); err != nil {
			return err
		}
	} else {
		if v := pol.Policy; v == nil {
			if err := d.Set("policy", ""); err != nil {
				return err
			}
		} else if err := d.Set("policy", normalizeJson(*v)); err != nil {
			return err
		}
	}

	// Read the website configuration
	ws, err := s3conn.GetBucketWebsite(&s3.GetBucketWebsiteInput{
		Bucket: aws.String(d.Id()),
	})
	var websites []map[string]interface{}
	if err == nil {
		w := make(map[string]interface{})

		if v := ws.IndexDocument; v != nil {
			w["index_document"] = *v.Suffix
		}

		if v := ws.ErrorDocument; v != nil {
			w["error_document"] = *v.Key
		}

		if v := ws.RedirectAllRequestsTo; v != nil {
			w["redirect_all_requests_to"] = *v.HostName
		}

		websites = append(websites, w)
	}
	if err := d.Set("website", websites); err != nil {
		return err
	}

	// Add the region as an attribute
	location, err := s3conn.GetBucketLocation(
		&s3.GetBucketLocationInput{
			Bucket: aws.String(d.Id()),
		},
	)
	if err != nil {
		return err
	}
	var region string
	if location.LocationConstraint != nil {
		region = *location.LocationConstraint
	}
	region = normalizeRegion(region)
	if err := d.Set("region", region); err != nil {
		return err
	}

	// Add the hosted zone ID for this bucket's region as an attribute
	hostedZoneID := HostedZoneIDForRegion(region)
	if err := d.Set("hosted_zone_id", hostedZoneID); err != nil {
		return err
	}

	// Add website_endpoint as an attribute
	endpoint, err := websiteEndpoint(s3conn, d)
	if err != nil {
		return err
	}
	if err := d.Set("website_endpoint", endpoint); err != nil {
		return err
	}

	tagSet, err := getTagSetS3(s3conn, d.Id())
	if err != nil {
		return err
	}

	if err := d.Set("tags", tagsToMapS3(tagSet)); err != nil {
		return err
	}

	return nil
}

func resourceAwsS3BucketDelete(d *schema.ResourceData, meta interface{}) error {
	s3conn := meta.(*AWSClient).s3conn

	log.Printf("[DEBUG] S3 Delete Bucket: %s", d.Id())
	_, err := s3conn.DeleteBucket(&s3.DeleteBucketInput{
		Bucket: aws.String(d.Id()),
	})
	if err != nil {
		ec2err, ok := err.(awserr.Error)
		if ok && ec2err.Code() == "BucketNotEmpty" {
			if d.Get("force_destroy").(bool) {
				// bucket may have things delete them
				log.Printf("[DEBUG] S3 Bucket attempting to forceDestroy %+v", err)

				bucket := d.Get("bucket").(string)
				resp, err := s3conn.ListObjects(
					&s3.ListObjectsInput{
						Bucket: aws.String(bucket),
					},
				)

				if err != nil {
					return fmt.Errorf("Error S3 Bucket list Objects err: %s", err)
				}

				objectsToDelete := make([]*s3.ObjectIdentifier, len(resp.Contents))
				for i, v := range resp.Contents {
					objectsToDelete[i] = &s3.ObjectIdentifier{
						Key: v.Key,
					}
				}
				_, err = s3conn.DeleteObjects(
					&s3.DeleteObjectsInput{
						Bucket: aws.String(bucket),
						Delete: &s3.Delete{
							Objects: objectsToDelete,
						},
					},
				)
				if err != nil {
					return fmt.Errorf("Error S3 Bucket force_destroy error deleting: %s", err)
				}

				// this line recurses until all objects are deleted or an error is returned
				return resourceAwsS3BucketDelete(d, meta)
			}
		}
		return fmt.Errorf("Error deleting S3 Bucket: %s", err)
	}
	return nil
}

func resourceAwsS3BucketPolicyUpdate(s3conn *s3.S3, d *schema.ResourceData) error {
	bucket := d.Get("bucket").(string)
	policy := d.Get("policy").(string)

	if policy != "" {
		log.Printf("[DEBUG] S3 bucket: %s, put policy: %s", bucket, policy)

		_, err := s3conn.PutBucketPolicy(&s3.PutBucketPolicyInput{
			Bucket: aws.String(bucket),
			Policy: aws.String(policy),
		})

		if err != nil {
			return fmt.Errorf("Error putting S3 policy: %s", err)
		}
	} else {
		log.Printf("[DEBUG] S3 bucket: %s, delete policy: %s", bucket, policy)
		_, err := s3conn.DeleteBucketPolicy(&s3.DeleteBucketPolicyInput{
			Bucket: aws.String(bucket),
		})

		if err != nil {
			return fmt.Errorf("Error deleting S3 policy: %s", err)
		}
	}

	return nil
}

func resourceAwsS3BucketWebsiteUpdate(s3conn *s3.S3, d *schema.ResourceData) error {
	ws := d.Get("website").([]interface{})

	if len(ws) == 1 {
		w := ws[0].(map[string]interface{})
		return resourceAwsS3BucketWebsitePut(s3conn, d, w)
	} else if len(ws) == 0 {
		return resourceAwsS3BucketWebsiteDelete(s3conn, d)
	} else {
		return fmt.Errorf("Cannot specify more than one website.")
	}
}

func resourceAwsS3BucketWebsitePut(s3conn *s3.S3, d *schema.ResourceData, website map[string]interface{}) error {
	bucket := d.Get("bucket").(string)

	indexDocument := website["index_document"].(string)
	errorDocument := website["error_document"].(string)
	redirectAllRequestsTo := website["redirect_all_requests_to"].(string)

	if indexDocument == "" && redirectAllRequestsTo == "" {
		return fmt.Errorf("Must specify either index_document or redirect_all_requests_to.")
	}

	websiteConfiguration := &s3.WebsiteConfiguration{}

	if indexDocument != "" {
		websiteConfiguration.IndexDocument = &s3.IndexDocument{Suffix: aws.String(indexDocument)}
	}

	if errorDocument != "" {
		websiteConfiguration.ErrorDocument = &s3.ErrorDocument{Key: aws.String(errorDocument)}
	}

	if redirectAllRequestsTo != "" {
		websiteConfiguration.RedirectAllRequestsTo = &s3.RedirectAllRequestsTo{HostName: aws.String(redirectAllRequestsTo)}
	}

	putInput := &s3.PutBucketWebsiteInput{
		Bucket:               aws.String(bucket),
		WebsiteConfiguration: websiteConfiguration,
	}

	log.Printf("[DEBUG] S3 put bucket website: %#v", putInput)

	_, err := s3conn.PutBucketWebsite(putInput)
	if err != nil {
		return fmt.Errorf("Error putting S3 website: %s", err)
	}

	return nil
}

func resourceAwsS3BucketWebsiteDelete(s3conn *s3.S3, d *schema.ResourceData) error {
	bucket := d.Get("bucket").(string)
	deleteInput := &s3.DeleteBucketWebsiteInput{Bucket: aws.String(bucket)}

	log.Printf("[DEBUG] S3 delete bucket website: %#v", deleteInput)

	_, err := s3conn.DeleteBucketWebsite(deleteInput)
	if err != nil {
		return fmt.Errorf("Error deleting S3 website: %s", err)
	}

	return nil
}

func websiteEndpoint(s3conn *s3.S3, d *schema.ResourceData) (string, error) {
	// If the bucket doesn't have a website configuration, return an empty
	// endpoint
	if _, ok := d.GetOk("website"); !ok {
		return "", nil
	}

	bucket := d.Get("bucket").(string)

	// Lookup the region for this bucket
	location, err := s3conn.GetBucketLocation(
		&s3.GetBucketLocationInput{
			Bucket: aws.String(bucket),
		},
	)
	if err != nil {
		return "", err
	}
	var region string
	if location.LocationConstraint != nil {
		region = *location.LocationConstraint
	}

	return WebsiteEndpointUrl(bucket, region), nil
}

func WebsiteEndpointUrl(bucket string, region string) string {
	region = normalizeRegion(region)

	// Frankfurt(and probably future) regions uses different syntax for website endpoints
	// http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteEndpoints.html
	if region == "eu-central-1" {
		return fmt.Sprintf("%s.s3-website.%s.amazonaws.com", bucket, region)
	}

	return fmt.Sprintf("%s.s3-website-%s.amazonaws.com", bucket, region)
}

func normalizeJson(jsonString interface{}) string {
	if jsonString == nil {
		return ""
	}
	j := make(map[string]interface{})
	err := json.Unmarshal([]byte(jsonString.(string)), &j)
	if err != nil {
		return fmt.Sprintf("Error parsing JSON: %s", err)
	}
	b, _ := json.Marshal(j)
	return string(b[:])
}

func normalizeRegion(region string) string {
	// Default to us-east-1 if the bucket doesn't have a region:
	// http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETlocation.html
	if region == "" {
		region = "us-east-1"
	}

	return region
}
