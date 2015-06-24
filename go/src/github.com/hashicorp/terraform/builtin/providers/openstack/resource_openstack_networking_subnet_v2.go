package openstack

import (
	"fmt"
	"log"

	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/rackspace/gophercloud/openstack/networking/v2/subnets"
)

func resourceNetworkingSubnetV2() *schema.Resource {
	return &schema.Resource{
		Create: resourceNetworkingSubnetV2Create,
		Read:   resourceNetworkingSubnetV2Read,
		Update: resourceNetworkingSubnetV2Update,
		Delete: resourceNetworkingSubnetV2Delete,

		Schema: map[string]*schema.Schema{
			"region": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				ForceNew:    true,
				DefaultFunc: envDefaultFuncAllowMissing("OS_REGION_NAME"),
			},
			"network_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"cidr": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
			},
			"tenant_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
				Computed: true,
			},
			"allocation_pools": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"start": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"end": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
					},
				},
			},
			"gateway_ip": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
				Computed: true,
			},
			"ip_version": &schema.Schema{
				Type:     schema.TypeInt,
				Required: true,
				ForceNew: true,
			},
			"enable_dhcp": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: false,
				Computed: true,
			},
			"dns_nameservers": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				ForceNew: false,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Set: func(v interface{}) int {
					return hashcode.String(v.(string))
				},
			},
			"host_routes": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"destination_cidr": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"next_hop": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
					},
				},
			},
		},
	}
}

func resourceNetworkingSubnetV2Create(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	createOpts := subnets.CreateOpts{
		NetworkID:       d.Get("network_id").(string),
		CIDR:            d.Get("cidr").(string),
		Name:            d.Get("name").(string),
		TenantID:        d.Get("tenant_id").(string),
		AllocationPools: resourceSubnetAllocationPoolsV2(d),
		GatewayIP:       d.Get("gateway_ip").(string),
		IPVersion:       d.Get("ip_version").(int),
		DNSNameservers:  resourceSubnetDNSNameserversV2(d),
		HostRoutes:      resourceSubnetHostRoutesV2(d),
	}

	if raw, ok := d.GetOk("enable_dhcp"); ok {
		value := raw.(bool)
		createOpts.EnableDHCP = &value
	}

	log.Printf("[DEBUG] Create Options: %#v", createOpts)
	s, err := subnets.Create(networkingClient, createOpts).Extract()
	if err != nil {
		return fmt.Errorf("Error creating OpenStack Neutron subnet: %s", err)
	}
	log.Printf("[INFO] Subnet ID: %s", s.ID)

	d.SetId(s.ID)

	return resourceNetworkingSubnetV2Read(d, meta)
}

func resourceNetworkingSubnetV2Read(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	s, err := subnets.Get(networkingClient, d.Id()).Extract()
	if err != nil {
		return CheckDeleted(d, err, "subnet")
	}

	log.Printf("[DEBUG] Retreived Subnet %s: %+v", d.Id(), s)

	d.Set("newtork_id", s.NetworkID)
	d.Set("cidr", s.CIDR)
	d.Set("ip_version", s.IPVersion)
	d.Set("name", s.Name)
	d.Set("tenant_id", s.TenantID)
	d.Set("allocation_pools", s.AllocationPools)
	d.Set("gateway_ip", s.GatewayIP)
	d.Set("enable_dhcp", s.EnableDHCP)
	d.Set("dns_nameservers", s.DNSNameservers)
	d.Set("host_routes", s.HostRoutes)

	return nil
}

func resourceNetworkingSubnetV2Update(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	var updateOpts subnets.UpdateOpts

	if d.HasChange("name") {
		updateOpts.Name = d.Get("name").(string)
	}

	if d.HasChange("gateway_ip") {
		updateOpts.GatewayIP = d.Get("gateway_ip").(string)
	}

	if d.HasChange("dns_nameservers") {
		updateOpts.DNSNameservers = resourceSubnetDNSNameserversV2(d)
	}

	if d.HasChange("host_routes") {
		updateOpts.HostRoutes = resourceSubnetHostRoutesV2(d)
	}

	if d.HasChange("enable_dhcp") {
		v := d.Get("enable_dhcp").(bool)
		updateOpts.EnableDHCP = &v
	}

	log.Printf("[DEBUG] Updating Subnet %s with options: %+v", d.Id(), updateOpts)

	_, err = subnets.Update(networkingClient, d.Id(), updateOpts).Extract()
	if err != nil {
		return fmt.Errorf("Error updating OpenStack Neutron Subnet: %s", err)
	}

	return resourceNetworkingSubnetV2Read(d, meta)
}

func resourceNetworkingSubnetV2Delete(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)
	networkingClient, err := config.networkingV2Client(d.Get("region").(string))
	if err != nil {
		return fmt.Errorf("Error creating OpenStack networking client: %s", err)
	}

	err = subnets.Delete(networkingClient, d.Id()).ExtractErr()
	if err != nil {
		return fmt.Errorf("Error deleting OpenStack Neutron Subnet: %s", err)
	}

	d.SetId("")
	return nil
}

func resourceSubnetAllocationPoolsV2(d *schema.ResourceData) []subnets.AllocationPool {
	rawAPs := d.Get("allocation_pools").([]interface{})
	aps := make([]subnets.AllocationPool, len(rawAPs))
	for i, raw := range rawAPs {
		rawMap := raw.(map[string]interface{})
		aps[i] = subnets.AllocationPool{
			Start: rawMap["start"].(string),
			End:   rawMap["end"].(string),
		}
	}
	return aps
}

func resourceSubnetDNSNameserversV2(d *schema.ResourceData) []string {
	rawDNSN := d.Get("dns_nameservers").(*schema.Set)
	dnsn := make([]string, rawDNSN.Len())
	for i, raw := range rawDNSN.List() {
		dnsn[i] = raw.(string)
	}
	return dnsn
}

func resourceSubnetHostRoutesV2(d *schema.ResourceData) []subnets.HostRoute {
	rawHR := d.Get("host_routes").([]interface{})
	hr := make([]subnets.HostRoute, len(rawHR))
	for i, raw := range rawHR {
		rawMap := raw.(map[string]interface{})
		hr[i] = subnets.HostRoute{
			DestinationCIDR: rawMap["destination_cidr"].(string),
			NextHop:         rawMap["next_hop"].(string),
		}
	}
	return hr
}
