package aws

import (
	"bytes"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"

	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsVpnConnection() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsVpnConnectionCreate,
		Read:   resourceAwsVpnConnectionRead,
		Update: resourceAwsVpnConnectionUpdate,
		Delete: resourceAwsVpnConnectionDelete,

		Schema: map[string]*schema.Schema{
			"vpn_gateway_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"customer_gateway_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"type": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"static_routes_only": &schema.Schema{
				Type:     schema.TypeBool,
				Required: true,
				ForceNew: true,
			},

			"tags": tagsSchema(),

			// Begin read only attributes
			"customer_gateway_configuration": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
				Optional: true,
			},

			"routes": &schema.Schema{
				Type:     schema.TypeSet,
				Computed: true,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"destination_cidr_block": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},

						"source": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},

						"state": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},
					},
				},
				Set: func(v interface{}) int {
					var buf bytes.Buffer
					m := v.(map[string]interface{})
					buf.WriteString(fmt.Sprintf("%s-", m["destination_cidr_block"].(string)))
					buf.WriteString(fmt.Sprintf("%s-", m["source"].(string)))
					buf.WriteString(fmt.Sprintf("%s-", m["state"].(string)))
					return hashcode.String(buf.String())
				},
			},

			"vgw_telemetry": &schema.Schema{
				Type:     schema.TypeSet,
				Computed: true,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"accepted_route_count": &schema.Schema{
							Type:     schema.TypeInt,
							Computed: true,
							Optional: true,
						},

						"last_status_change": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},

						"outside_ip_address": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},

						"status": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},

						"status_message": &schema.Schema{
							Type:     schema.TypeString,
							Computed: true,
							Optional: true,
						},
					},
				},
				Set: func(v interface{}) int {
					var buf bytes.Buffer
					m := v.(map[string]interface{})
					buf.WriteString(fmt.Sprintf("%s-", m["outside_ip_address"].(string)))
					return hashcode.String(buf.String())
				},
			},
		},
	}
}

func resourceAwsVpnConnectionCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	connectOpts := &ec2.VPNConnectionOptionsSpecification{
		StaticRoutesOnly: aws.Boolean(d.Get("static_routes_only").(bool)),
	}

	createOpts := &ec2.CreateVPNConnectionInput{
		CustomerGatewayID: aws.String(d.Get("customer_gateway_id").(string)),
		Options:           connectOpts,
		Type:              aws.String(d.Get("type").(string)),
		VPNGatewayID:      aws.String(d.Get("vpn_gateway_id").(string)),
	}

	// Create the VPN Connection
	log.Printf("[DEBUG] Creating vpn connection")
	resp, err := conn.CreateVPNConnection(createOpts)
	if err != nil {
		return fmt.Errorf("Error creating vpn connection: %s", err)
	}

	// Store the ID
	vpnConnection := resp.VPNConnection
	d.SetId(*vpnConnection.VPNConnectionID)
	log.Printf("[INFO] VPN connection ID: %s", *vpnConnection.VPNConnectionID)

	// Wait for the connection to become available. This has an obscenely
	// high default timeout because AWS VPN connections are notoriously
	// slow at coming up or going down. There's also no point in checking
	// more frequently than every ten seconds.
	stateConf := &resource.StateChangeConf{
		Pending:    []string{"pending"},
		Target:     "available",
		Refresh:    vpnConnectionRefreshFunc(conn, *vpnConnection.VPNConnectionID),
		Timeout:    30 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 10 * time.Second,
	}

	_, stateErr := stateConf.WaitForState()
	if stateErr != nil {
		return fmt.Errorf(
			"Error waiting for VPN connection (%s) to become ready: %s",
			*vpnConnection.VPNConnectionID, err)
	}

	// Create tags.
	if err := setTags(conn, d); err != nil {
		return err
	}

	// Read off the API to populate our RO fields.
	return resourceAwsVpnConnectionRead(d, meta)
}

func vpnConnectionRefreshFunc(conn *ec2.EC2, connectionId string) resource.StateRefreshFunc {
	return func() (interface{}, string, error) {
		resp, err := conn.DescribeVPNConnections(&ec2.DescribeVPNConnectionsInput{
			VPNConnectionIDs: []*string{aws.String(connectionId)},
		})

		if err != nil {
			if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnConnectionID.NotFound" {
				resp = nil
			} else {
				log.Printf("Error on VPNConnectionRefresh: %s", err)
				return nil, "", err
			}
		}

		if resp == nil || len(resp.VPNConnections) == 0 {
			return nil, "", nil
		}

		connection := resp.VPNConnections[0]
		return connection, *connection.State, nil
	}
}

func resourceAwsVpnConnectionRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	resp, err := conn.DescribeVPNConnections(&ec2.DescribeVPNConnectionsInput{
		VPNConnectionIDs: []*string{aws.String(d.Id())},
	})
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnConnectionID.NotFound" {
			d.SetId("")
			return nil
		} else {
			log.Printf("[ERROR] Error finding VPN connection: %s", err)
			return err
		}
	}

	if len(resp.VPNConnections) != 1 {
		return fmt.Errorf("[ERROR] Error finding VPN connection: %s", d.Id())
	}

	vpnConnection := resp.VPNConnections[0]

	// Set attributes under the user's control.
	d.Set("vpn_gateway_id", vpnConnection.VPNGatewayID)
	d.Set("customer_gateway_id", vpnConnection.CustomerGatewayID)
	d.Set("type", vpnConnection.Type)
	d.Set("tags", tagsToMap(vpnConnection.Tags))

	if vpnConnection.Options != nil {
		if err := d.Set("static_routes_only", vpnConnection.Options.StaticRoutesOnly); err != nil {
			return err
		}
	}

	// Set read only attributes.
	d.Set("customer_gateway_configuration", vpnConnection.CustomerGatewayConfiguration)
	if err := d.Set("vgw_telemetry", telemetryToMapList(vpnConnection.VGWTelemetry)); err != nil {
		return err
	}
	if vpnConnection.Routes != nil {
		if err := d.Set("routes", routesToMapList(vpnConnection.Routes)); err != nil {
			return err
		}
	}

	return nil
}

func resourceAwsVpnConnectionUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	// Update tags if required.
	if err := setTags(conn, d); err != nil {
		return err
	}

	d.SetPartial("tags")

	return resourceAwsVpnConnectionRead(d, meta)
}

func resourceAwsVpnConnectionDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	_, err := conn.DeleteVPNConnection(&ec2.DeleteVPNConnectionInput{
		VPNConnectionID: aws.String(d.Id()),
	})
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVpnConnectionID.NotFound" {
			d.SetId("")
			return nil
		} else {
			log.Printf("[ERROR] Error deleting VPN connection: %s", err)
			return err
		}
	}

	// These things can take quite a while to tear themselves down and any
	// attempt to modify resources they reference (e.g. CustomerGateways or
	// VPN Gateways) before deletion will result in an error. Furthermore,
	// they don't just disappear. The go into "deleted" state. We need to
	// wait to ensure any other modifications the user might make to their
	// VPC stack can safely run.
	stateConf := &resource.StateChangeConf{
		Pending:    []string{"deleting"},
		Target:     "deleted",
		Refresh:    vpnConnectionRefreshFunc(conn, d.Id()),
		Timeout:    30 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 10 * time.Second,
	}

	_, stateErr := stateConf.WaitForState()
	if stateErr != nil {
		return fmt.Errorf(
			"Error waiting for VPN connection (%s) to delete: %s", d.Id(), err)
	}

	return nil
}

// routesToMapList turns the list of routes into a list of maps.
func routesToMapList(routes []*ec2.VPNStaticRoute) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(routes))
	for _, r := range routes {
		staticRoute := make(map[string]interface{})
		staticRoute["destination_cidr_block"] = *r.DestinationCIDRBlock
		staticRoute["state"] = *r.State

		if r.Source != nil {
			staticRoute["source"] = *r.Source
		}

		result = append(result, staticRoute)
	}

	return result
}

// telemetryToMapList turns the VGW telemetry into a list of maps.
func telemetryToMapList(telemetry []*ec2.VGWTelemetry) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(telemetry))
	for _, t := range telemetry {
		vgw := make(map[string]interface{})
		vgw["accepted_route_count"] = *t.AcceptedRouteCount
		vgw["outside_ip_address"] = *t.OutsideIPAddress
		vgw["status"] = *t.Status
		vgw["status_message"] = *t.StatusMessage

		// LastStatusChange is a time.Time(). Convert it into a string
		// so it can be handled by schema's type system.
		vgw["last_status_change"] = t.LastStatusChange.String()
		result = append(result, vgw)
	}

	return result
}
