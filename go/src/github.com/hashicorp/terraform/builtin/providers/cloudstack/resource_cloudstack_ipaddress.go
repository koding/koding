package cloudstack

import (
	"fmt"
	"log"
	"strings"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/xanzy/go-cloudstack/cloudstack"
)

func resourceCloudStackIPAddress() *schema.Resource {
	return &schema.Resource{
		Create: resourceCloudStackIPAddressCreate,
		Read:   resourceCloudStackIPAddressRead,
		Delete: resourceCloudStackIPAddressDelete,

		Schema: map[string]*schema.Schema{
			"network": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"vpc": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"ipaddress": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func resourceCloudStackIPAddressCreate(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	if err := verifyIPAddressParams(d); err != nil {
		return err
	}

	// Create a new parameter struct
	p := cs.Address.NewAssociateIpAddressParams()

	if network, ok := d.GetOk("network"); ok {
		// Retrieve the network UUID
		networkid, e := retrieveUUID(cs, "network", network.(string))
		if e != nil {
			return e.Error()
		}

		// Set the networkid
		p.SetNetworkid(networkid)
	}

	if vpc, ok := d.GetOk("vpc"); ok {
		// Retrieve the vpc UUID
		vpcid, e := retrieveUUID(cs, "vpc", vpc.(string))
		if e != nil {
			return e.Error()
		}

		// Set the vpcid
		p.SetVpcid(vpcid)
	}

	// Associate a new IP address
	r, err := cs.Address.AssociateIpAddress(p)
	if err != nil {
		return fmt.Errorf("Error associating a new IP address: %s", err)
	}

	d.SetId(r.Id)

	return resourceCloudStackIPAddressRead(d, meta)
}

func resourceCloudStackIPAddressRead(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Get the network ACL list details
	f, count, err := cs.Address.GetPublicIpAddressByID(d.Id())
	if err != nil {
		if count == 0 {
			log.Printf(
				"[DEBUG] IP address with ID %s is no longer associated", d.Id())
			d.SetId("")
			return nil
		}

		return err
	}

	// Updated the IP address
	d.Set("ipaddress", f.Ipaddress)

	if _, ok := d.GetOk("network"); ok {
		// Get the network details
		n, _, err := cs.Network.GetNetworkByID(f.Associatednetworkid)
		if err != nil {
			return err
		}

		d.Set("network", n.Name)
	}

	if _, ok := d.GetOk("vpc"); ok {
		// Get the VPC details
		v, _, err := cs.VPC.GetVPCByID(f.Vpcid)
		if err != nil {
			return err
		}

		d.Set("vpc", v.Name)
	}

	return nil
}

func resourceCloudStackIPAddressDelete(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Create a new parameter struct
	p := cs.Address.NewDisassociateIpAddressParams(d.Id())

	// Disassociate the IP address
	if _, err := cs.Address.DisassociateIpAddress(p); err != nil {
		// This is a very poor way to be told the UUID does no longer exist :(
		if strings.Contains(err.Error(), fmt.Sprintf(
			"Invalid parameter id value=%s due to incorrect long value format, "+
				"or entity does not exist", d.Id())) {
			return nil
		}

		return fmt.Errorf("Error disassociating IP address %s: %s", d.Get("name").(string), err)
	}

	return nil
}

func verifyIPAddressParams(d *schema.ResourceData) error {
	_, network := d.GetOk("network")
	_, vpc := d.GetOk("vpc")

	if (network && vpc) || (!network && !vpc) {
		return fmt.Errorf(
			"You must supply a value for either (so not both) the 'network' or 'vpc' parameter")
	}

	return nil
}
