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

func resourceAwsApiGatewayRestApi() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsApiGatewayRestApiCreate,
		Read:   resourceAwsApiGatewayRestApiRead,
		Update: resourceAwsApiGatewayRestApiUpdate,
		Delete: resourceAwsApiGatewayRestApiDelete,

		Schema: map[string]*schema.Schema{
			"name": {
				Type:     schema.TypeString,
				Required: true,
			},

			"description": {
				Type:     schema.TypeString,
				Optional: true,
			},

			"binary_media_types": {
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
			},

			"root_resource_id": {
				Type:     schema.TypeString,
				Computed: true,
			},

			"created_date": {
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func resourceAwsApiGatewayRestApiCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Creating API Gateway")

	var description *string
	if d.Get("description").(string) != "" {
		description = aws.String(d.Get("description").(string))
	}

	params := &apigateway.CreateRestApiInput{
		Name:        aws.String(d.Get("name").(string)),
		Description: description,
	}

	binaryMediaTypes, binaryMediaTypesOk := d.GetOk("binary_media_types")
	if binaryMediaTypesOk {
		params.BinaryMediaTypes = expandStringList(binaryMediaTypes.([]interface{}))
	}

	gateway, err := conn.CreateRestApi(params)
	if err != nil {
		return fmt.Errorf("Error creating API Gateway: %s", err)
	}

	d.SetId(*gateway.Id)

	if err = resourceAwsApiGatewayRestApiRefreshResources(d, meta); err != nil {
		return err
	}

	return resourceAwsApiGatewayRestApiRead(d, meta)
}

func resourceAwsApiGatewayRestApiRefreshResources(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway

	resp, err := conn.GetResources(&apigateway.GetResourcesInput{
		RestApiId: aws.String(d.Id()),
	})
	if err != nil {
		return err
	}

	for _, item := range resp.Items {
		if *item.Path == "/" {
			d.Set("root_resource_id", item.Id)
			break
		}
	}

	return nil
}

func resourceAwsApiGatewayRestApiRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Reading API Gateway %s", d.Id())

	api, err := conn.GetRestApi(&apigateway.GetRestApiInput{
		RestApiId: aws.String(d.Id()),
	})
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok && awsErr.Code() == "NotFoundException" {
			d.SetId("")
			return nil
		}
		return err
	}

	d.Set("name", api.Name)
	d.Set("description", api.Description)
	d.Set("binary_media_types", api.BinaryMediaTypes)

	if err := d.Set("created_date", api.CreatedDate.Format(time.RFC3339)); err != nil {
		log.Printf("[DEBUG] Error setting created_date: %s", err)
	}

	return nil
}

func resourceAwsApiGatewayRestApiUpdateOperations(d *schema.ResourceData) []*apigateway.PatchOperation {
	operations := make([]*apigateway.PatchOperation, 0)

	if d.HasChange("name") {
		operations = append(operations, &apigateway.PatchOperation{
			Op:    aws.String("replace"),
			Path:  aws.String("/name"),
			Value: aws.String(d.Get("name").(string)),
		})
	}

	if d.HasChange("description") {
		operations = append(operations, &apigateway.PatchOperation{
			Op:    aws.String("replace"),
			Path:  aws.String("/description"),
			Value: aws.String(d.Get("description").(string)),
		})
	}

	return operations
}

func resourceAwsApiGatewayRestApiUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Updating API Gateway %s", d.Id())

	_, err := conn.UpdateRestApi(&apigateway.UpdateRestApiInput{
		RestApiId:       aws.String(d.Id()),
		PatchOperations: resourceAwsApiGatewayRestApiUpdateOperations(d),
	})

	if err != nil {
		return err
	}
	log.Printf("[DEBUG] Updated API Gateway %s", d.Id())

	return resourceAwsApiGatewayRestApiRead(d, meta)
}

func resourceAwsApiGatewayRestApiDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).apigateway
	log.Printf("[DEBUG] Deleting API Gateway: %s", d.Id())

	return resource.Retry(10*time.Minute, func() *resource.RetryError {
		_, err := conn.DeleteRestApi(&apigateway.DeleteRestApiInput{
			RestApiId: aws.String(d.Id()),
		})
		if err == nil {
			return nil
		}

		if apigatewayErr, ok := err.(awserr.Error); ok && apigatewayErr.Code() == "NotFoundException" {
			return nil
		}

		return resource.NonRetryableError(err)
	})
}
