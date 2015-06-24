package aws

import (
	"fmt"
	"log"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"

	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsVpnConnectionRoute() *schema.Resource {
	return &schema.Resource{
		// You can't update a route. You can just delete one and make
		// a new one.
		Create: resourceAwsVpnConnectionRouteCreate,
		Update: resourceAwsVpnConnectionRouteCreate,

		Read:   resourceAwsVpnConnectionRouteRead,
		Delete: resourceAwsVpnConnectionRouteDelete,

		Schema: map[string]*schema.Schema{
			"destination_cidr_block": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"vpn_connection_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
		},
	}
}

func resourceAwsVpnConnectionRouteCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	createOpts := &ec2.CreateVPNConnectionRouteInput{
		DestinationCIDRBlock: aws.String(d.Get("destination_cidr_block").(string)),
		VPNConnectionID:      aws.String(d.Get("vpn_connection_id").(string)),
	}

	// Create the route.
	log.Printf("[DEBUG] Creating VPN connection route")
	_, err := conn.CreateVPNConnectionRoute(createOpts)
	if err != nil {
		return fmt.Errorf("Error creating VPN connection route: %s", err)
	}

	// Store the ID by the only two data we have available to us.
	d.SetId(fmt.Sprintf("%s:%s", *createOpts.DestinationCIDRBlock, *createOpts.VPNConnectionID))

	return resourceAwsVpnConnectionRouteRead(d, meta)
}

func resourceAwsVpnConnectionRouteRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	cidrBlock, vpnConnectionId := resourceAwsVpnConnectionRouteParseId(d.Id())

	routeFilters := []*ec2.Filter{
		&ec2.Filter{
			Name:   aws.String("route.destination-cidr-block"),
			Values: []*string{aws.String(cidrBlock)},
		},
		&ec2.Filter{
			Name:   aws.String("vpn-connection-id"),
			Values: []*string{aws.String(vpnConnectionId)},
		},
	}

	// Technically, we know everything there is to know about the route
	// from its ID, but we still want to catch cases where it changes
	// outside of terraform and results in a stale state file. Hence,
	// conduct a read.
	resp, err := conn.DescribeVPNConnections(&ec2.DescribeVPNConnectionsInput{
		Filters: routeFilters,
	})
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnConnectionID.NotFound" {
			d.SetId("")
			return nil
		} else {
			log.Printf("[ERROR] Error finding VPN connection route: %s", err)
			return err
		}
	}

	vpnConnection := resp.VPNConnections[0]

	var found bool
	for _, r := range vpnConnection.Routes {
		if *r.DestinationCIDRBlock == cidrBlock {
			d.Set("destination_cidr_block", *r.DestinationCIDRBlock)
			d.Set("vpn_connection_id", *vpnConnection.VPNConnectionID)
			found = true
		}
	}
	if !found {
		// Something other than terraform eliminated the route.
		d.SetId("")
	}

	return nil
}

func resourceAwsVpnConnectionRouteDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	_, err := conn.DeleteVPNConnectionRoute(&ec2.DeleteVPNConnectionRouteInput{
		DestinationCIDRBlock: aws.String(d.Get("destination_cidr_block").(string)),
		VPNConnectionID:      aws.String(d.Get("vpn_connection_id").(string)),
	})
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnConnectionID.NotFound" {
			d.SetId("")
			return nil
		} else {
			log.Printf("[ERROR] Error deleting VPN connection route: %s", err)
			return err
		}
	}

	return nil
}

func resourceAwsVpnConnectionRouteParseId(id string) (string, string) {
	parts := strings.SplitN(id, ":", 2)
	return parts[0], parts[1]
}
