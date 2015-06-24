package aws

import (
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsVpnGateway() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsVpnGatewayCreate,
		Read:   resourceAwsVpnGatewayRead,
		Update: resourceAwsVpnGatewayUpdate,
		Delete: resourceAwsVpnGatewayDelete,

		Schema: map[string]*schema.Schema{
			"availability_zone": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"vpc_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"tags": tagsSchema(),
		},
	}
}

func resourceAwsVpnGatewayCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	createOpts := &ec2.CreateVPNGatewayInput{
		AvailabilityZone: aws.String(d.Get("availability_zone").(string)),
		Type:             aws.String("ipsec.1"),
	}

	// Create the VPN gateway
	log.Printf("[DEBUG] Creating VPN gateway")
	resp, err := conn.CreateVPNGateway(createOpts)
	if err != nil {
		return fmt.Errorf("Error creating VPN gateway: %s", err)
	}

	// Get the ID and store it
	vpnGateway := resp.VPNGateway
	d.SetId(*vpnGateway.VPNGatewayID)
	log.Printf("[INFO] VPN Gateway ID: %s", *vpnGateway.VPNGatewayID)

	// Attach the VPN gateway to the correct VPC
	return resourceAwsVpnGatewayUpdate(d, meta)
}

func resourceAwsVpnGatewayRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	resp, err := conn.DescribeVPNGateways(&ec2.DescribeVPNGatewaysInput{
		VPNGatewayIDs: []*string{aws.String(d.Id())},
	})
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnGatewayID.NotFound" {
			d.SetId("")
			return nil
		} else {
			log.Printf("[ERROR] Error finding VpnGateway: %s", err)
			return err
		}
	}

	vpnGateway := resp.VPNGateways[0]
	if vpnGateway == nil {
		// Seems we have lost our VPN gateway
		d.SetId("")
		return nil
	}

	if len(vpnGateway.VPCAttachments) == 0 {
		// Gateway exists but not attached to the VPC
		d.Set("vpc_id", "")
	} else {
		d.Set("vpc_id", vpnGateway.VPCAttachments[0].VPCID)
	}
	d.Set("availability_zone", vpnGateway.AvailabilityZone)
	d.Set("tags", tagsToMap(vpnGateway.Tags))

	return nil
}

func resourceAwsVpnGatewayUpdate(d *schema.ResourceData, meta interface{}) error {
	if d.HasChange("vpc_id") {
		// If we're already attached, detach it first
		if err := resourceAwsVpnGatewayDetach(d, meta); err != nil {
			return err
		}

		// Attach the VPN gateway to the new vpc
		if err := resourceAwsVpnGatewayAttach(d, meta); err != nil {
			return err
		}
	}

	conn := meta.(*AWSClient).ec2conn

	if err := setTags(conn, d); err != nil {
		return err
	}

	d.SetPartial("tags")

	return resourceAwsVpnGatewayRead(d, meta)
}

func resourceAwsVpnGatewayDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	// Detach if it is attached
	if err := resourceAwsVpnGatewayDetach(d, meta); err != nil {
		return err
	}

	log.Printf("[INFO] Deleting VPN gateway: %s", d.Id())

	return resource.Retry(5*time.Minute, func() error {
		_, err := conn.DeleteVPNGateway(&ec2.DeleteVPNGatewayInput{
			VPNGatewayID: aws.String(d.Id()),
		})
		if err == nil {
			return nil
		}

		ec2err, ok := err.(awserr.Error)
		if !ok {
			return err
		}

		switch ec2err.Code() {
		case "InvalidVpnGatewayID.NotFound":
			return nil
		case "IncorrectState":
			return err // retry
		}

		return resource.RetryError{Err: err}
	})
}

func resourceAwsVpnGatewayAttach(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	if d.Get("vpc_id").(string) == "" {
		log.Printf(
			"[DEBUG] Not attaching VPN Gateway '%s' as no VPC ID is set",
			d.Id())
		return nil
	}

	log.Printf(
		"[INFO] Attaching VPN Gateway '%s' to VPC '%s'",
		d.Id(),
		d.Get("vpc_id").(string))

	_, err := conn.AttachVPNGateway(&ec2.AttachVPNGatewayInput{
		VPNGatewayID: aws.String(d.Id()),
		VPCID:        aws.String(d.Get("vpc_id").(string)),
	})
	if err != nil {
		return err
	}

	// A note on the states below: the AWS docs (as of July, 2014) say
	// that the states would be: attached, attaching, detached, detaching,
	// but when running, I noticed that the state is usually "available" when
	// it is attached.

	// Wait for it to be fully attached before continuing
	log.Printf("[DEBUG] Waiting for VPN gateway (%s) to attach", d.Id())
	stateConf := &resource.StateChangeConf{
		Pending: []string{"detached", "attaching"},
		Target:  "available",
		Refresh: vpnGatewayAttachStateRefreshFunc(conn, d.Id(), "available"),
		Timeout: 1 * time.Minute,
	}
	if _, err := stateConf.WaitForState(); err != nil {
		return fmt.Errorf(
			"Error waiting for VPN gateway (%s) to attach: %s",
			d.Id(), err)
	}

	return nil
}

func resourceAwsVpnGatewayDetach(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	// Get the old VPC ID to detach from
	vpcID, _ := d.GetChange("vpc_id")

	if vpcID.(string) == "" {
		log.Printf(
			"[DEBUG] Not detaching VPN Gateway '%s' as no VPC ID is set",
			d.Id())
		return nil
	}

	log.Printf(
		"[INFO] Detaching VPN Gateway '%s' from VPC '%s'",
		d.Id(),
		vpcID.(string))

	wait := true
	_, err := conn.DetachVPNGateway(&ec2.DetachVPNGatewayInput{
		VPNGatewayID: aws.String(d.Id()),
		VPCID:        aws.String(vpcID.(string)),
	})
	if err != nil {
		ec2err, ok := err.(awserr.Error)
		if ok {
			if ec2err.Code() == "InvalidVpnGatewayID.NotFound" {
				err = nil
				wait = false
			} else if ec2err.Code() == "InvalidVpnGatewayAttachment.NotFound" {
				err = nil
				wait = false
			}
		}

		if err != nil {
			return err
		}
	}

	if !wait {
		return nil
	}

	// Wait for it to be fully detached before continuing
	log.Printf("[DEBUG] Waiting for VPN gateway (%s) to detach", d.Id())
	stateConf := &resource.StateChangeConf{
		Pending: []string{"attached", "detaching", "available"},
		Target:  "detached",
		Refresh: vpnGatewayAttachStateRefreshFunc(conn, d.Id(), "detached"),
		Timeout: 1 * time.Minute,
	}
	if _, err := stateConf.WaitForState(); err != nil {
		return fmt.Errorf(
			"Error waiting for vpn gateway (%s) to detach: %s",
			d.Id(), err)
	}

	return nil
}

// vpnGatewayAttachStateRefreshFunc returns a resource.StateRefreshFunc that is used to watch
// the state of a VPN gateway's attachment
func vpnGatewayAttachStateRefreshFunc(conn *ec2.EC2, id string, expected string) resource.StateRefreshFunc {
	var start time.Time
	return func() (interface{}, string, error) {
		if start.IsZero() {
			start = time.Now()
		}

		resp, err := conn.DescribeVPNGateways(&ec2.DescribeVPNGatewaysInput{
			VPNGatewayIDs: []*string{aws.String(id)},
		})
		if err != nil {
			if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnGatewayID.NotFound" {
				resp = nil
			} else {
				log.Printf("[ERROR] Error on VpnGatewayStateRefresh: %s", err)
				return nil, "", err
			}
		}

		if resp == nil {
			// Sometimes AWS just has consistency issues and doesn't see
			// our instance yet. Return an empty state.
			return nil, "", nil
		}

		vpnGateway := resp.VPNGateways[0]

		if time.Now().Sub(start) > 10*time.Second {
			return vpnGateway, expected, nil
		}

		if len(vpnGateway.VPCAttachments) == 0 {
			// No attachments, we're detached
			return vpnGateway, "detached", nil
		}

		return vpnGateway, *vpnGateway.VPCAttachments[0].State, nil
	}
}
