package aws

import (
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/waf"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsWafIPSet() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsWafIPSetCreate,
		Read:   resourceAwsWafIPSetRead,
		Update: resourceAwsWafIPSetUpdate,
		Delete: resourceAwsWafIPSetDelete,

		Schema: map[string]*schema.Schema{
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"ip_set_descriptors": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"type": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"value": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
					},
				},
			},
		},
	}
}

func resourceAwsWafIPSetCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).wafconn

	wr := newWafRetryer(conn, "global")
	out, err := wr.RetryWithToken(func(token *string) (interface{}, error) {
		params := &waf.CreateIPSetInput{
			ChangeToken: token,
			Name:        aws.String(d.Get("name").(string)),
		}
		return conn.CreateIPSet(params)
	})
	if err != nil {
		return err
	}
	resp := out.(*waf.CreateIPSetOutput)
	d.SetId(*resp.IPSet.IPSetId)
	return resourceAwsWafIPSetUpdate(d, meta)
}

func resourceAwsWafIPSetRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).wafconn

	params := &waf.GetIPSetInput{
		IPSetId: aws.String(d.Id()),
	}

	resp, err := conn.GetIPSet(params)
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok && awsErr.Code() == "WAFNonexistentItemException" {
			log.Printf("[WARN] WAF IPSet (%s) not found, error code (404)", d.Id())
			d.SetId("")
			return nil
		}

		return err
	}

	var descriptors []map[string]interface{}

	for _, descriptor := range resp.IPSet.IPSetDescriptors {
		d := map[string]interface{}{
			"type":  *descriptor.Type,
			"value": *descriptor.Value,
		}
		descriptors = append(descriptors, d)
	}

	d.Set("ip_set_descriptors", descriptors)

	d.Set("name", resp.IPSet.Name)

	return nil
}

func resourceAwsWafIPSetUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).wafconn

	if d.HasChange("ip_set_descriptors") {
		o, n := d.GetChange("ip_set_descriptors")
		oldD, newD := o.(*schema.Set).List(), n.(*schema.Set).List()

		err := updateWafIpSetDescriptors(d.Id(), oldD, newD, conn)
		if err != nil {
			return fmt.Errorf("Error Updating WAF IPSet: %s", err)
		}
	}

	return resourceAwsWafIPSetRead(d, meta)
}

func resourceAwsWafIPSetDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).wafconn

	oldDescriptors := d.Get("ip_set_descriptors").(*schema.Set).List()

	if len(oldDescriptors) > 0 {
		noDescriptors := []interface{}{}
		err := updateWafIpSetDescriptors(d.Id(), oldDescriptors, noDescriptors, conn)
		if err != nil {
			return fmt.Errorf("Error updating IPSetDescriptors: %s", err)
		}
	}

	wr := newWafRetryer(conn, "global")
	_, err := wr.RetryWithToken(func(token *string) (interface{}, error) {
		req := &waf.DeleteIPSetInput{
			ChangeToken: token,
			IPSetId:     aws.String(d.Id()),
		}
		log.Printf("[INFO] Deleting WAF IPSet")
		return conn.DeleteIPSet(req)
	})
	if err != nil {
		return fmt.Errorf("Error Deleting WAF IPSet: %s", err)
	}

	return nil
}

func updateWafIpSetDescriptors(id string, oldD, newD []interface{}, conn *waf.WAF) error {
	wr := newWafRetryer(conn, "global")
	_, err := wr.RetryWithToken(func(token *string) (interface{}, error) {
		req := &waf.UpdateIPSetInput{
			ChangeToken: token,
			IPSetId:     aws.String(id),
			Updates:     diffWafIpSetDescriptors(oldD, newD),
		}
		log.Printf("[INFO] Updating IPSet descriptors: %s", req)
		return conn.UpdateIPSet(req)
	})
	if err != nil {
		return fmt.Errorf("Error Updating WAF IPSet: %s", err)
	}

	return nil
}

func diffWafIpSetDescriptors(oldD, newD []interface{}) []*waf.IPSetUpdate {
	updates := make([]*waf.IPSetUpdate, 0)

	for _, od := range oldD {
		descriptor := od.(map[string]interface{})

		if idx, contains := sliceContainsMap(newD, descriptor); contains {
			newD = append(newD[:idx], newD[idx+1:]...)
			continue
		}

		updates = append(updates, &waf.IPSetUpdate{
			Action: aws.String(waf.ChangeActionDelete),
			IPSetDescriptor: &waf.IPSetDescriptor{
				Type:  aws.String(descriptor["type"].(string)),
				Value: aws.String(descriptor["value"].(string)),
			},
		})
	}

	for _, nd := range newD {
		descriptor := nd.(map[string]interface{})

		updates = append(updates, &waf.IPSetUpdate{
			Action: aws.String(waf.ChangeActionInsert),
			IPSetDescriptor: &waf.IPSetDescriptor{
				Type:  aws.String(descriptor["type"].(string)),
				Value: aws.String(descriptor["value"].(string)),
			},
		})
	}
	return updates
}
