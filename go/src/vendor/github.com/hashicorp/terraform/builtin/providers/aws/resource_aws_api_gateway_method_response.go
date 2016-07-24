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

func resourceAwsApiGatewayMethodResponse() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsApiGatewayMethodResponseCreate,
		Read:   resourceAwsApiGatewayMethodResponseRead,
		Update: resourceAwsApiGatewayMethodResponseUpdate,
		Delete: resourceAwsApiGatewayMethodResponseDelete,

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

			"response_models": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				Elem:     schema.TypeString,
			},
		},
	}
}

func resourceAwsApiGatewayMethodResponseCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	models := make(map[string]string)
	for k, v := range d.Get("response_models").(map[string]interface{}) {
		models[k] = v.(string)
	}

	_, err := conn.PutMethodResponse(&apigateway.PutMethodResponseInput{
		HttpMethod:     aws.String(d.Get("http_method").(string)),
		ResourceId:     aws.String(d.Get("resource_id").(string)),
		RestApiId:      aws.String(d.Get("rest_api_id").(string)),
		StatusCode:     aws.String(d.Get("status_code").(string)),
		ResponseModels: aws.StringMap(models),
		// TODO implement once [GH-2143](https://github.com/hashicorp/terraform/issues/2143) has been implemented
		ResponseParameters: nil,
	})
	if err != nil {
		return fmt.Errorf("Error creating API Gateway Method Response: %s", err)
	}

	d.SetId(fmt.Sprintf("agmr-%s-%s-%s-%s", d.Get("rest_api_id").(string), d.Get("resource_id").(string), d.Get("http_method").(string), d.Get("status_code").(string)))
	log.Printf("[DEBUG] API Gateway Method ID: %s", d.Id())

	return nil
}

func resourceAwsApiGatewayMethodResponseRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	log.Printf("[DEBUG] Reading API Gateway Method %s", d.Id())
	methodResponse, err := conn.GetMethodResponse(&apigateway.GetMethodResponseInput{
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

	log.Printf("[DEBUG] Received API Gateway Method: %s", methodResponse)
	d.Set("response_models", aws.StringValueMap(methodResponse.ResponseModels))
	d.SetId(fmt.Sprintf("agmr-%s-%s-%s-%s", d.Get("rest_api_id").(string), d.Get("resource_id").(string), d.Get("http_method").(string), d.Get("status_code").(string)))

	return nil
}

func resourceAwsApiGatewayMethodResponseUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	log.Printf("[DEBUG] Updating API Gateway Method Response %s", d.Id())
	operations := make([]*apigateway.PatchOperation, 0)

	if d.HasChange("response_models") {
		operations = append(operations, expandApiGatewayRequestResponseModelOperations(d, "response_models", "responseModels")...)
	}

	out, err := conn.UpdateMethodResponse(&apigateway.UpdateMethodResponseInput{
		HttpMethod:      aws.String(d.Get("http_method").(string)),
		ResourceId:      aws.String(d.Get("resource_id").(string)),
		RestApiId:       aws.String(d.Get("rest_api_id").(string)),
		StatusCode:      aws.String(d.Get("status_code").(string)),
		PatchOperations: operations,
	})

	if err != nil {
		return err
	}

	log.Printf("[DEBUG] Received API Gateway Method Response: %s", out)

	return resourceAwsApiGatewayMethodResponseRead(d, meta)
}

func resourceAwsApiGatewayMethodResponseDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Deleting API Gateway Method Response: %s", d.Id())

	return resource.Retry(5*time.Minute, func() *resource.RetryError {
		_, err := conn.DeleteMethodResponse(&apigateway.DeleteMethodResponseInput{
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
