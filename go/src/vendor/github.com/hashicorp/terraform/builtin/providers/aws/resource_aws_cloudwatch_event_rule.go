package aws

import (
	"fmt"
	"log"
	"regexp"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	events "github.com/aws/aws-sdk-go/service/cloudwatchevents"
	"github.com/hashicorp/errwrap"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsCloudWatchEventRule() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsCloudWatchEventRuleCreate,
		Read:   resourceAwsCloudWatchEventRuleRead,
		Update: resourceAwsCloudWatchEventRuleUpdate,
		Delete: resourceAwsCloudWatchEventRuleDelete,
		Importer: &schema.ResourceImporter{
			State: schema.ImportStatePassthrough,
		},

		Schema: map[string]*schema.Schema{
			"name": &schema.Schema{
				Type:         schema.TypeString,
				Required:     true,
				ForceNew:     true,
				ValidateFunc: validateCloudWatchEventRuleName,
			},
			"schedule_expression": &schema.Schema{
				Type:         schema.TypeString,
				Optional:     true,
				ValidateFunc: validateMaxLength(256),
			},
			"event_pattern": &schema.Schema{
				Type:         schema.TypeString,
				Optional:     true,
				ValidateFunc: validateEventPatternValue(2048),
				StateFunc: func(v interface{}) string {
					json, _ := normalizeJsonString(v)
					return json
				},
			},
			"description": &schema.Schema{
				Type:         schema.TypeString,
				Optional:     true,
				ValidateFunc: validateMaxLength(512),
			},
			"role_arn": &schema.Schema{
				Type:         schema.TypeString,
				Optional:     true,
				ValidateFunc: validateMaxLength(1600),
			},
			"is_enabled": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  true,
			},
			"arn": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func resourceAwsCloudWatchEventRuleCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).cloudwatcheventsconn

	input, err := buildPutRuleInputStruct(d)
	if err != nil {
		return errwrap.Wrapf("Creating CloudWatch Event Rule failed: {{err}}", err)
	}
	log.Printf("[DEBUG] Creating CloudWatch Event Rule: %s", input)

	// IAM Roles take some time to propagate
	var out *events.PutRuleOutput
	err = resource.Retry(30*time.Second, func() *resource.RetryError {
		var err error
		out, err = conn.PutRule(input)
		pattern := regexp.MustCompile("cannot be assumed by principal '[a-z]+\\.amazonaws\\.com'\\.$")
		if err != nil {
			if awsErr, ok := err.(awserr.Error); ok {
				if awsErr.Code() == "ValidationException" && pattern.MatchString(awsErr.Message()) {
					log.Printf("[DEBUG] Retrying creation of CloudWatch Event Rule %q", *input.Name)
					return resource.RetryableError(err)
				}
			}
			return resource.NonRetryableError(err)
		}
		return nil
	})
	if err != nil {
		return errwrap.Wrapf("Creating CloudWatch Event Rule failed: {{err}}", err)
	}

	d.Set("arn", out.RuleArn)
	d.SetId(d.Get("name").(string))

	log.Printf("[INFO] CloudWatch Event Rule %q created", *out.RuleArn)

	return resourceAwsCloudWatchEventRuleUpdate(d, meta)
}

func resourceAwsCloudWatchEventRuleRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).cloudwatcheventsconn

	input := events.DescribeRuleInput{
		Name: aws.String(d.Id()),
	}
	log.Printf("[DEBUG] Reading CloudWatch Event Rule: %s", input)
	out, err := conn.DescribeRule(&input)
	if awsErr, ok := err.(awserr.Error); ok {
		if awsErr.Code() == "ResourceNotFoundException" {
			log.Printf("[WARN] Removing CloudWatch Event Rule %q because it's gone.", d.Id())
			d.SetId("")
			return nil
		}
	}
	if err != nil {
		return err
	}
	log.Printf("[DEBUG] Found Event Rule: %s", out)

	d.Set("arn", out.Arn)
	d.Set("description", out.Description)
	if out.EventPattern != nil {
		pattern, err := normalizeJsonString(*out.EventPattern)
		if err != nil {
			return errwrap.Wrapf("event pattern contains an invalid JSON: {{err}}", err)
		}
		d.Set("event_pattern", pattern)
	}
	d.Set("name", out.Name)
	d.Set("role_arn", out.RoleArn)
	d.Set("schedule_expression", out.ScheduleExpression)

	boolState, err := getBooleanStateFromString(*out.State)
	if err != nil {
		return err
	}
	log.Printf("[DEBUG] Setting boolean state: %t", boolState)
	d.Set("is_enabled", boolState)

	return nil
}

func resourceAwsCloudWatchEventRuleUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).cloudwatcheventsconn

	if d.HasChange("is_enabled") && d.Get("is_enabled").(bool) {
		log.Printf("[DEBUG] Enabling CloudWatch Event Rule %q", d.Id())
		_, err := conn.EnableRule(&events.EnableRuleInput{
			Name: aws.String(d.Id()),
		})
		if err != nil {
			return err
		}
		log.Printf("[DEBUG] CloudWatch Event Rule (%q) enabled", d.Id())
	}

	input, err := buildPutRuleInputStruct(d)
	if err != nil {
		return errwrap.Wrapf("Updating CloudWatch Event Rule failed: {{err}}", err)
	}
	log.Printf("[DEBUG] Updating CloudWatch Event Rule: %s", input)

	// IAM Roles take some time to propagate
	err = resource.Retry(30*time.Second, func() *resource.RetryError {
		_, err := conn.PutRule(input)
		pattern := regexp.MustCompile("cannot be assumed by principal '[a-z]+\\.amazonaws\\.com'\\.$")
		if err != nil {
			if awsErr, ok := err.(awserr.Error); ok {
				if awsErr.Code() == "ValidationException" && pattern.MatchString(awsErr.Message()) {
					log.Printf("[DEBUG] Retrying update of CloudWatch Event Rule %q", *input.Name)
					return resource.RetryableError(err)
				}
			}
			return resource.NonRetryableError(err)
		}
		return nil
	})
	if err != nil {
		return errwrap.Wrapf("Updating CloudWatch Event Rule failed: {{err}}", err)
	}

	if d.HasChange("is_enabled") && !d.Get("is_enabled").(bool) {
		log.Printf("[DEBUG] Disabling CloudWatch Event Rule %q", d.Id())
		_, err := conn.DisableRule(&events.DisableRuleInput{
			Name: aws.String(d.Id()),
		})
		if err != nil {
			return err
		}
		log.Printf("[DEBUG] CloudWatch Event Rule (%q) disabled", d.Id())
	}

	return resourceAwsCloudWatchEventRuleRead(d, meta)
}

func resourceAwsCloudWatchEventRuleDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).cloudwatcheventsconn

	log.Printf("[INFO] Deleting CloudWatch Event Rule: %s", d.Id())
	_, err := conn.DeleteRule(&events.DeleteRuleInput{
		Name: aws.String(d.Id()),
	})
	if err != nil {
		return fmt.Errorf("Error deleting CloudWatch Event Rule: %s", err)
	}
	log.Println("[INFO] CloudWatch Event Rule deleted")

	d.SetId("")

	return nil
}

func buildPutRuleInputStruct(d *schema.ResourceData) (*events.PutRuleInput, error) {
	input := events.PutRuleInput{
		Name: aws.String(d.Get("name").(string)),
	}
	if v, ok := d.GetOk("description"); ok {
		input.Description = aws.String(v.(string))
	}
	if v, ok := d.GetOk("event_pattern"); ok {
		pattern, err := normalizeJsonString(v)
		if err != nil {
			return nil, errwrap.Wrapf("event pattern contains an invalid JSON: {{err}}", err)
		}
		input.EventPattern = aws.String(pattern)
	}
	if v, ok := d.GetOk("role_arn"); ok {
		input.RoleArn = aws.String(v.(string))
	}
	if v, ok := d.GetOk("schedule_expression"); ok {
		input.ScheduleExpression = aws.String(v.(string))
	}

	input.State = aws.String(getStringStateFromBoolean(d.Get("is_enabled").(bool)))

	return &input, nil
}

// State is represented as (ENABLED|DISABLED) in the API
func getBooleanStateFromString(state string) (bool, error) {
	if state == "ENABLED" {
		return true, nil
	} else if state == "DISABLED" {
		return false, nil
	}
	// We don't just blindly trust AWS as they tend to return
	// unexpected values in similar cases (different casing etc.)
	return false, fmt.Errorf("Failed converting state %q into boolean", state)
}

// State is represented as (ENABLED|DISABLED) in the API
func getStringStateFromBoolean(isEnabled bool) string {
	if isEnabled {
		return "ENABLED"
	}
	return "DISABLED"
}

func validateEventPatternValue(length int) schema.SchemaValidateFunc {
	return func(v interface{}, k string) (ws []string, errors []error) {
		json, err := normalizeJsonString(v)
		if err != nil {
			errors = append(errors, fmt.Errorf("%q contains an invalid JSON: %s", k, err))

			// Invalid JSON? Return immediately,
			// there is no need to collect other
			// errors.
			return
		}

		// Check whether the normalized JSON is within the given length.
		if len(json) > length {
			errors = append(errors, fmt.Errorf(
				"%q cannot be longer than %d characters: %q", k, length, json))
		}
		return
	}
}
