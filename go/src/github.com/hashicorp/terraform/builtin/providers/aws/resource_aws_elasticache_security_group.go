package aws

import (
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsElasticacheSecurityGroup() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsElasticacheSecurityGroupCreate,
		Read:   resourceAwsElasticacheSecurityGroupRead,
		Delete: resourceAwsElasticacheSecurityGroupDelete,

		Schema: map[string]*schema.Schema{
			"description": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"security_group_names": &schema.Schema{
				Type:     schema.TypeSet,
				Required: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Set: func(v interface{}) int {
					return hashcode.String(v.(string))
				},
			},
		},
	}
}

func resourceAwsElasticacheSecurityGroupCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).elasticacheconn

	name := d.Get("name").(string)
	desc := d.Get("description").(string)
	nameSet := d.Get("security_group_names").(*schema.Set)

	names := make([]string, nameSet.Len())
	for i, name := range nameSet.List() {
		names[i] = name.(string)
	}

	log.Printf("[DEBUG] Cache security group create: name: %s, description: %s, security_group_names: %v", name, desc, names)
	res, err := conn.CreateCacheSecurityGroup(&elasticache.CreateCacheSecurityGroupInput{
		Description:            aws.String(desc),
		CacheSecurityGroupName: aws.String(name),
	})
	if err != nil {
		return fmt.Errorf("Error creating CacheSecurityGroup: %s", err)
	}

	for _, n := range names {
		log.Printf("[DEBUG] Authorize cache security group ingress name: %v, ec2 security group name: %v", name, n)
		_, err = conn.AuthorizeCacheSecurityGroupIngress(&elasticache.AuthorizeCacheSecurityGroupIngressInput{
			CacheSecurityGroupName:  aws.String(name),
			EC2SecurityGroupName:    aws.String(n),
			EC2SecurityGroupOwnerID: aws.String(*res.CacheSecurityGroup.OwnerID),
		})
		if err != nil {
			log.Printf("[ERROR] Failed to authorize: %v", err)
			_, err := conn.DeleteCacheSecurityGroup(&elasticache.DeleteCacheSecurityGroupInput{
				CacheSecurityGroupName: aws.String(d.Id()),
			})
			log.Printf("[ERROR] Revert cache security group: %v", err)
		}
	}

	d.SetId(name)

	return nil
}

func resourceAwsElasticacheSecurityGroupRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).elasticacheconn
	req := &elasticache.DescribeCacheSecurityGroupsInput{
		CacheSecurityGroupName: aws.String(d.Get("name").(string)),
	}

	res, err := conn.DescribeCacheSecurityGroups(req)
	if err != nil {
		return err
	}
	if len(res.CacheSecurityGroups) == 0 {
		return fmt.Errorf("Error missing %v", d.Get("name"))
	}

	var group *elasticache.CacheSecurityGroup
	for _, g := range res.CacheSecurityGroups {
		log.Printf("[DEBUG] CacheSecurityGroupName: %v, id: %v", g.CacheSecurityGroupName, d.Id())
		if *g.CacheSecurityGroupName == d.Id() {
			group = g
		}
	}
	if group == nil {
		return fmt.Errorf("Error retrieving cache security group: %v", res)
	}

	d.Set("name", group.CacheSecurityGroupName)
	d.Set("description", group.Description)

	return nil
}

func resourceAwsElasticacheSecurityGroupDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).elasticacheconn

	log.Printf("[DEBUG] Cache security group delete: %s", d.Id())

	return resource.Retry(5*time.Minute, func() error {
		_, err := conn.DeleteCacheSecurityGroup(&elasticache.DeleteCacheSecurityGroupInput{
			CacheSecurityGroupName: aws.String(d.Id()),
		})
		if err != nil {
			apierr, ok := err.(awserr.Error)
			if !ok {
				return err
			}
			log.Printf("[DEBUG] APIError.Code: %v", apierr.Code)
			switch apierr.Code() {
			case "InvalidCacheSecurityGroupState":
				return err
			case "DependencyViolation":
				// If it is a dependency violation, we want to retry
				return err
			default:
				return resource.RetryError{Err: err}
			}
		}
		return nil
	})
}
