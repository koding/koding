package vagrantkite

import (
	"fmt"
	"koding/kites/kloud/klient"
	"log"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/koding/kite"
)

const klientFuncName = "vagrant.create"

type vagrantCreateReq struct {
	FilePath string
	Hostname string
	Box      string
	Memory   int
	Cpus     int
}

func resourceVagrantKiteBuild() *schema.Resource {
	return &schema.Resource{
		Create: resourceMachineCreate,
		Read:   resourceMachineNoop,
		Update: resourceMachineNoop,
		Delete: resourceMachineNoop,

		Schema: map[string]*schema.Schema{
			// Full path of the file for Vagrantfile
			"queryString": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				Description: "Kite Query string for finding which klient to send the commands",
			},
			"filePath": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				Description: "Full path of the file for Vagrantfile",
			},
			"box": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Box type of underlying Vagrant machine. By default ubuntu/trusty64",
			},
			"hostname": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Hostname of the Vagrant machine. Defaults to klient's username",
			},
			"memory": &schema.Schema{
				Type:        schema.TypeInt,
				Optional:    true,
				Description: "Memory(MB) of the underlying Vagrant box. Defaults to 1024",
			},
			"cpus": &schema.Schema{
				Type:        schema.TypeInt,
				Optional:    true,
				Description: "Number of CPU's to be used for the underlying Vagrant box. Defaults to 1",
			},
		},
	}
}

// resourceMachineCreate creates a new vagrant machine in remote klient host
func resourceMachineCreate(d *schema.ResourceData, meta interface{}) error {
	queryString := d.Get("queryString").(string)

	args := &vagrantCreateReq{
		FilePath: d.Get("filePath").(string),
		Box:      d.Get("box").(string),
		Hostname: d.Get("hostname").(string),
		Memory:   d.Get("memory").(int),
		Cpus:     d.Get("cpus").(int),
	}

	if err := sendCommand(klientFuncName, queryString, args); err != nil {
		return err
	}

	d.SetId(queryString)

	return nil
}

// sendCommand sends given command with given args to the kite is specified with
// queryString, each command timeouts in 10 seconds
func sendCommand(command string, queryString string, args interface{}) error {
	c, err := NewClient()
	if err != nil {
		return err
	}
	defer c.Close()

	// Get the klient.
	klientRef, err := klient.ConnectTimeout(c.Kite, queryString, time.Second*10)
	if err != nil {
		if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
			c.Log.Error(
				"[%s] Klient is not registered to Kontrol. Err: %s",
				queryString,
				err.Error(),
			)

			return nil // if the machine is not open, we cant do anything
		}

		return err
	}
	defer klientRef.Close()

	_, err = klientRef.Client.Tell(command, args)
	return err
}

func resourceMachineNoop(d *schema.ResourceData, meta interface{}) error { return nil }
