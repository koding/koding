package cloudstack

import (
	"fmt"
	"log"
	"strings"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/xanzy/go-cloudstack/cloudstack"
)

func resourceCloudStackVPC() *schema.Resource {
	return &schema.Resource{
		Create: resourceCloudStackVPCCreate,
		Read:   resourceCloudStackVPCRead,
		Update: resourceCloudStackVPCUpdate,
		Delete: resourceCloudStackVPCDelete,

		Schema: map[string]*schema.Schema{
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"display_text": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"cidr": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"vpc_offering": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"zone": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
		},
	}
}

func resourceCloudStackVPCCreate(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	name := d.Get("name").(string)

	// Retrieve the vpc_offering UUID
	vpcofferingid, e := retrieveUUID(cs, "vpc_offering", d.Get("vpc_offering").(string))
	if e != nil {
		return e.Error()
	}

	// Retrieve the zone UUID
	zoneid, e := retrieveUUID(cs, "zone", d.Get("zone").(string))
	if e != nil {
		return e.Error()
	}

	// Set the display text
	displaytext, ok := d.GetOk("display_text")
	if !ok {
		displaytext = name
	}

	// Create a new parameter struct
	p := cs.VPC.NewCreateVPCParams(d.Get("cidr").(string), displaytext.(string), name, vpcofferingid, zoneid)

	// Create the new VPC
	r, err := cs.VPC.CreateVPC(p)
	if err != nil {
		return fmt.Errorf("Error creating VPC %s: %s", name, err)
	}

	d.SetId(r.Id)

	return resourceCloudStackVPCRead(d, meta)
}

func resourceCloudStackVPCRead(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Get the VPC details
	v, count, err := cs.VPC.GetVPCByID(d.Id())
	if err != nil {
		if count == 0 {
			log.Printf(
				"[DEBUG] VPC %s does no longer exist", d.Get("name").(string))
			d.SetId("")
			return nil
		}

		return err
	}

	d.Set("name", v.Name)
	d.Set("display_text", v.Displaytext)
	d.Set("cidr", v.Cidr)

	setValueOrUUID(d, "zone", v.Zonename, v.Zoneid)

	// Get the VPC offering details
	o, _, err := cs.VPC.GetVPCOfferingByID(v.Vpcofferingid)
	if err != nil {
		return err
	}

	setValueOrUUID(d, "vpc_offering", o.Name, v.Vpcofferingid)

	return nil
}

func resourceCloudStackVPCUpdate(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Check if the name or display text is changed
	if d.HasChange("name") || d.HasChange("display_text") {
		// Create a new parameter struct
		p := cs.VPC.NewUpdateVPCParams(d.Id())

		// Set the display text
		displaytext, ok := d.GetOk("display_text")
		if !ok {
			displaytext = d.Get("name")
		}
		// Set the (new) display text
		p.SetDisplaytext(displaytext.(string))

		// Update the VPC
		_, err := cs.VPC.UpdateVPC(p)
		if err != nil {
			return fmt.Errorf(
				"Error updating VPC %s: %s", d.Get("name").(string), err)
		}
	}

	return resourceCloudStackVPCRead(d, meta)
}

func resourceCloudStackVPCDelete(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Create a new parameter struct
	p := cs.VPC.NewDeleteVPCParams(d.Id())

	// Delete the VPC
	_, err := cs.VPC.DeleteVPC(p)
	if err != nil {
		// This is a very poor way to be told the UUID does no longer exist :(
		if strings.Contains(err.Error(), fmt.Sprintf(
			"Invalid parameter id value=%s due to incorrect long value format, "+
				"or entity does not exist", d.Id())) {
			return nil
		}

		return fmt.Errorf("Error deleting VPC %s: %s", d.Get("name").(string), err)
	}

	return nil
}
