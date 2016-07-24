package aws

import (
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/apigateway"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsApiGatewayIntegrationResponse() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsApiGatewayIntegrationResponseCreate,
		Read:   resourceAwsApiGatewayIntegrationResponseRead,
		Update: resourceAwsApiGatewayIntegrationResponseUpdate,
		Delete: resourceAwsApiGatewayIntegrationResponseDelete,

		Schema: map[string]*schema.Schema{
			"rest_api_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"resource_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"http_method": &schema.Schema{
				Type:         schema.TypeString,
				Required:     true,
				ForceNew:     true,
				ValidateFunc: validateHTTPMethod,
			},

			"status_code": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"selection_pattern": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"response_templates": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				Elem:     schema.TypeString,
			},
		},
	}
}

func resourceAwsApiGatewayIntegrationResponseCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	templates := make(map[string]string)
	for k, v := range d.Get("response_templates").(map[string]interface{}) {
		templates[k] = v.(string)
	}

	_, err := conn.PutIntegrationResponse(&apigateway.PutIntegrationResponseInput{
		HttpMethod:        aws.String(d.Get("http_method").(string)),
		ResourceId:        aws.String(d.Get("resource_id").(string)),
		RestApiId:         aws.String(d.Get("rest_api_id").(string)),
		StatusCode:        aws.String(d.Get("status_code").(string)),
		ResponseTemplates: aws.StringMap(templates),
		// TODO implement once [GH-2143](https://github.com/hashicorp/terraform/issues/2143) has been implemented
		ResponseParameters: nil,
	})
	if err != nil {
		return fmt.Errorf("Error creating API Gateway Integration Response: %s", err)
	}

	d.SetId(fmt.Sprintf("agir-%s-%s-%s-%s", d.Get("rest_api_id").(string), d.Get("resource_id").(string), d.Get("http_method").(string), d.Get("status_code").(string)))
	log.Printf("[DEBUG] API Gateway Integration Response ID: %s", d.Id())

	return nil
}

func resourceAwsApiGatewayIntegrationResponseRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	log.Printf("[DEBUG] Reading API Gateway Integration Response %s", d.Id())
	integrationResponse, err := conn.GetIntegrationResponse(&apigateway.GetIntegrationResponseInput{
		HttpMethod: aws.String(d.Get("http_method").(string)),
		ResourceId: aws.String(d.Get("resource_id").(string)),
		RestApiId:  aws.String(d.Get("rest_api_id").(string)),
		StatusCode: aws.String(d.Get("status_code").(string)),
	})
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok && awsErr.Code() == "NotFoundException" {
			d.SetId("")
			return nil
		}
		return err
	}
	log.Printf("[DEBUG] Received API Gateway Integration Response: %s", integrationResponse)
	d.SetId(fmt.Sprintf("agir-%s-%s-%s-%s", d.Get("rest_api_id").(string), d.Get("resource_id").(string), d.Get("http_method").(string), d.Get("status_code").(string)))

	return nil
}

func resourceAwsApiGatewayIntegrationResponseUpdate(d *schema.ResourceData, meta interface{}) error {
	return resourceAwsApiGatewayIntegrationResponseCreate(d, meta)
}

func resourceAwsApiGatewayIntegrationResponseDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Deleting API Gateway Integration Response: %s", d.Id())

	return resource.Retry(5*time.Minute, func() *resource.RetryError {
		_, err := conn.DeleteIntegrationResponse(&apigateway.DeleteIntegrationResponseInput{
			HttpMethod: aws.String(d.Get("http_method").(string)),
			ResourceId: aws.String(d.Get("resource_id").(string)),
			RestApiId:  aws.String(d.Get("rest_api_id").(string)),
			StatusCode: aws.String(d.Get("status_code").(string)),
		})
		if err == nil {
			return nil
		}

		apigatewayErr, ok := err.(awserr.Error)
		if apigatewayErr.Code() == "NotFoundException" {
			return nil
		}

		if !ok {
			return resource.NonRetryableError(err)
		}

		return resource.NonRetryableError(err)
	})
}
