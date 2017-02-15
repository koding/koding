package vagrant

import (
	"errors"
	"fmt"

	"github.com/hashicorp/terraform/helper/schema"
)

func resourceVagrantBuild() *schema.Resource {
	return &schema.Resource{
		Create: resourceMachineCreate,
		Read:   resourceMachineNoop,
		Update: resourceMachineNoop,
		Delete: resourceMachineDelete,

		Schema: map[string]*schema.Schema{
			// Required configuration files
			"queryString": {
				Type:        schema.TypeString,
				Required:    true,
				Description: "Kite Query string for finding which klient to send the commands",
			},
			"filePath": {
				Type:        schema.TypeString,
				Required:    true,
				Description: "Full path of the file for Vagrantfile",
			},
			"provisionData": {
				Type:        schema.TypeString,
				Required:    true,
				Description: "JSON data encoded as base64 needed for provisioning the Vagrant box",
			},

			// Optional configuration fields
			"box": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Box type of underlying Vagrant machine. By default ubuntu/trusty64",
			},
			"hostname": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Hostname of the Vagrant machine. Defaults to klient's username",
			},
			"username": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Username of the Vagrant machine.",
			},
			"memory": {
				Type:        schema.TypeInt,
				Optional:    true,
				Description: "Memory(MB) of the underlying Vagrant box. Defaults to 1024",
			},
			"cpus": {
				Type:        schema.TypeInt,
				Optional:    true,
				Description: "Number of CPU's to be used for the underlying Vagrant box. Defaults to 1",
			},
			"user_data": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Custom script to be executed inside the Vagrant box after the main provisioning is finished.",
			},
			"debug": {
				Type:        schema.TypeBool,
				Optional:    true,
				Description: "Enables debug logging of the vagrant commands.",
			},
			"forwarded_ports": {
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"host": {
							Type:        schema.TypeInt,
							Optional:    true,
							Description: "Host value of the forwarded port.",
						},
						"guest": {
							Type:        schema.TypeInt,
							Required:    true,
							Description: "Guest port to forward.",
						},
					},
				},
			},
			"registerURL": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Register URL of the klient inside the Vagrant box",
			},
			"kontrolURL": {
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Kontrol URL of the klient inside the Vagrant box",
			},

			// Computes fields
			"klientHostURL": {
				Type:        schema.TypeString,
				Computed:    true,
				Description: "URL of the Klient inside the host machine where the Vagrant box residues",
			},
		},
	}
}

// resourceMachineCreate creates a new vagrant machine in remote klient host
func resourceMachineCreate(d *schema.ResourceData, meta interface{}) error {
	c, err := NewClient()
	if err != nil {
		return err
	}
	defer c.Close()

	queryString, ok := d.Get("queryString").(string)
	if !ok {
		return errors.New("invalid request: queryString filed is missing")
	}

	createReq, err := newCreateReq(d)
	if err != nil {
		return err
	}

	c.Log.Debug(`Calling "vagrant.create" on %q with %+v`, queryString, createReq)

	// the "vagrant.create" method returns the same parameters back. However if
	// we previously passed empty options, such as hostname, it returns the
	// final response.
	resp, err := c.Vagrant.Create(queryString, createReq)
	if err != nil {
		return err
	}

	err = c.Vagrant.Up(queryString, resp.FilePath)
	if err != nil {
		return fmt.Errorf("vagrant provisioning has failed: " + err.Error())
	}

	d.SetId(queryString)
	d.Set("filePath", resp.FilePath)
	d.Set("klientHostURL", resp.HostURL)
	d.Set("hostname", resp.Hostname)
	d.Set("box", resp.Box)
	d.Set("cpus", resp.Cpus)
	d.Set("memory", resp.Memory)

	return nil
}

func resourceMachineDelete(d *schema.ResourceData, meta interface{}) error {
	c, err := NewClient()
	if err != nil {
		return err
	}
	defer c.Close()

	queryString, ok := d.Get("queryString").(string)
	if !ok {
		return errors.New("invalid request: queryString field is missing")
	}

	filePath, ok := d.Get("filePath").(string)
	if !ok {
		return errors.New("invalid request: filePath field is missing")
	}

	c.Log.Debug(`Calling "vagrant.destroy" on %q with %q`, queryString, filePath)

	return c.Vagrant.Destroy(queryString, filePath)
}

func resourceMachineNoop(d *schema.ResourceData, meta interface{}) error { return nil }
