package openstack

import (
	"fmt"
	"log"
	"strconv"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/rackspace/gophercloud"
	"github.com/rackspace/gophercloud/openstack/networking/v2/extensions/layer3/floatingips"
	"github.com/rackspace/gophercloud/openstack/networking/v2/extensions/lbaas/vips"
)

func resourceLBVipV1() *schema.Resource {
	return &schema.Resource{
		Create: resourceLBVipV1Create,
		Read:   resourceLBVipV1Read,
		Update: resourceLBVipV1Update,
		Delete: resourceLBVipV1Delete,

		Schema: map[string]*schema.Schema{
			"region": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				ForceNew:    true,
				DefaultFunc: envDefaultFuncAllowMissing("OS_REGION_NAME"),
			},
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: false,
			},
			"subnet_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"protocol": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"port": &schema.Schema{
				Type:     schema.TypeInt,
				Required: true,
				ForceNew: true,
			},
			"pool_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: false,
			},
			"tenant_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},
			"address": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},
			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
			},
			"persistence": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				ForceNew: false,
			},
			"conn_limit": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				ForceNew: false,
			},
			"port_id": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
				ForceNew: false,
			},
			"floating_ip": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
			},
			"admin_state_up": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
			},
		},
	}
}

func resourceLBVipV1Create(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	createOpts := vips.CreateOpts{
		Name:         d.Get("name").(string),
		SubnetID:     d.Get("subnet_id").(string),
		Protocol:     d.Get("protocol").(string),
		ProtocolPort: d.Get("port").(int),
		PoolID:       d.Get("pool_id").(string),
		TenantID:     d.Get("tenant_id").(string),
		Address:      d.Get("address").(string),
		Description:  d.Get("description").(string),
		Persistence:  resourceVipPersistenceV1(d),
		ConnLimit:    gophercloud.MaybeInt(d.Get("conn_limit").(int)),
	}

	asuRaw := d.Get("admin_state_up").(string)
	if asuRaw != "" {
		asu, err := strconv.ParseBool(asuRaw)
		if err != nil {
			return fmt.Errorf("admin_state_up, if provided, must be either 'true' or 'false'")
		}
		createOpts.AdminStateUp = &asu
	}

	log.Printf("[DEBUG] Create Options: %#v", createOpts)
	p, err := vips.Create(networkingClient, createOpts).Extract()
	if err != nil {
		return fmt.Errorf("Error creating OpenStack LB VIP: %s", err)
	}
	log.Printf("[INFO] LB VIP ID: %s", p.ID)

	floatingIP := d.Get("floating_ip").(string)
	if floatingIP != "" {
		lbVipV1AssignFloatingIP(floatingIP, p.PortID, networkingClient)
	}

	d.SetId(p.ID)

	return resourceLBVipV1Read(d, meta)
}

func resourceLBVipV1Read(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	p, err := vips.Get(networkingClient, d.Id()).Extract()
	if err != nil {
		return CheckDeleted(d, err, "LB VIP")
	}

	log.Printf("[DEBUG] Retreived OpenStack LB VIP %s: %+v", d.Id(), p)

	d.Set("name", p.Name)
	d.Set("subnet_id", p.SubnetID)
	d.Set("protocol", p.Protocol)
	d.Set("port", p.ProtocolPort)
	d.Set("pool_id", p.PoolID)
	d.Set("port_id", p.PortID)

	if t, exists := d.GetOk("tenant_id"); exists && t != "" {
		d.Set("tenant_id", p.TenantID)
	} else {
		d.Set("tenant_id", "")
	}

	if t, exists := d.GetOk("address"); exists && t != "" {
		d.Set("address", p.Address)
	} else {
		d.Set("address", "")
	}

	if t, exists := d.GetOk("description"); exists && t != "" {
		d.Set("description", p.Description)
	} else {
		d.Set("description", "")
	}

	if t, exists := d.GetOk("persistence"); exists && t != "" {
		d.Set("persistence", p.Description)
	}

	if t, exists := d.GetOk("conn_limit"); exists && t != "" {
		d.Set("conn_limit", p.ConnLimit)
	} else {
		d.Set("conn_limit", "")
	}

	if t, exists := d.GetOk("admin_state_up"); exists && t != "" {
		d.Set("admin_state_up", strconv.FormatBool(p.AdminStateUp))
	} else {
		d.Set("admin_state_up", "")
	}

	return nil
}

func resourceLBVipV1Update(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	var updateOpts vips.UpdateOpts
	if d.HasChange("name") {
		updateOpts.Name = d.Get("name").(string)
	}
	if d.HasChange("pool_id") {
		updateOpts.PoolID = d.Get("pool_id").(string)
	}
	if d.HasChange("description") {
		updateOpts.Description = d.Get("description").(string)
	}
	if d.HasChange("persistence") {
		updateOpts.Persistence = resourceVipPersistenceV1(d)
	}
	if d.HasChange("conn_limit") {
		updateOpts.ConnLimit = gophercloud.MaybeInt(d.Get("conn_limit").(int))
	}
	if d.HasChange("floating_ip") {
		portID := d.Get("port_id").(string)

		// Searching for a floating IP assigned to the VIP
		listOpts := floatingips.ListOpts{
			PortID: portID,
		}
		page, err := floatingips.List(networkingClient, listOpts).AllPages()
		if err != nil {
			return err
		}

		fips, err := floatingips.ExtractFloatingIPs(page)
		if err != nil {
			return err
		}

		// If a floating IP is found we unassign it
		if len(fips) == 1 {
			updateOpts := floatingips.UpdateOpts{
				PortID: "",
			}
			if err = floatingips.Update(networkingClient, fips[0].ID, updateOpts).Err; err != nil {
				return err
			}
		}

		// Assign the updated floating IP
		floatingIP := d.Get("floating_ip").(string)
		if floatingIP != "" {
			lbVipV1AssignFloatingIP(floatingIP, portID, networkingClient)
		}
	}
	if d.HasChange("admin_state_up") {
		asuRaw := d.Get("admin_state_up").(string)
		if asuRaw != "" {
			asu, err := strconv.ParseBool(asuRaw)
			if err != nil {
				return fmt.Errorf("admin_state_up, if provided, must be either 'true' or 'false'")
			}
			updateOpts.AdminStateUp = &asu
		}
	}

	log.Printf("[DEBUG] Updating OpenStack LB VIP %s with options: %+v", d.Id(), updateOpts)

	_, err = vips.Update(networkingClient, d.Id(), updateOpts).Extract()
	if err != nil {
		return fmt.Errorf("Error updating OpenStack LB VIP: %s", err)
	}

	return resourceLBVipV1Read(d, meta)
}

func resourceLBVipV1Delete(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	err = vips.Delete(networkingClient, d.Id()).ExtractErr()
	if err != nil {
		return fmt.Errorf("Error deleting OpenStack LB VIP: %s", err)
	}

	d.SetId("")
	return nil
}

func resourceVipPersistenceV1(d *schema.ResourceData) *vips.SessionPersistence {
	rawP := d.Get("persistence").(interface{})
	rawMap := rawP.(map[string]interface{})
	if len(rawMap) != 0 {
		p := vips.SessionPersistence{}
		if t, ok := rawMap["type"]; ok {
			p.Type = t.(string)
		}
		if c, ok := rawMap["cookie_name"]; ok {
			p.CookieName = c.(string)
		}
		return &p
	}
	return nil
}

func lbVipV1AssignFloatingIP(floatingIP, portID string, networkingClient *gophercloud.ServiceClient) error {
	log.Printf("[DEBUG] Assigning floating IP %s to VIP %s", floatingIP, portID)

	listOpts := floatingips.ListOpts{
		FloatingIP: floatingIP,
	}
	page, err := floatingips.List(networkingClient, listOpts).AllPages()
	if err != nil {
		return err
	}

	fips, err := floatingips.ExtractFloatingIPs(page)
	if err != nil {
		return err
	}
	if len(fips) != 1 {
		return fmt.Errorf("Unable to retrieve floating IP '%s'", floatingIP)
	}

	updateOpts := floatingips.UpdateOpts{
		PortID: portID,
	}
	if err = floatingips.Update(networkingClient, fips[0].ID, updateOpts).Err; err != nil {
		return err
	}

	return nil
}
