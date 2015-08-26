package vagrantkite

import (
	"koding/kites/kloud/klient"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/koding/kite"
)

func resourceVagrantKiteBuild() *schema.Resource {
	return &schema.Resource{
		Create: resourceMachineCreate,
		Read:   resourceMachineNoop,
		Update: resourceMachineNoop,
		Delete: resourceMachineNoop,

		Schema: map[string]*schema.Schema{
			"queryString": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"vagrantFile": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"filePath": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

const klientFuncName = "vagrant.build"

type vagrantKiteReq struct {
	VagrantFile string
	FilePath    string
}

// resourceMachineCreate creates a new vagrant machine in remote klient host
func resourceMachineCreate(d *schema.ResourceData, meta interface{}) error {

	queryString := d.Get("queryString").(string)

	args := &vagrantKiteReq{
		VagrantFile: d.Get("vagrantFile").(string),
		FilePath:    d.Get("filePath").(string),
	}

	if err := sendCommand(klientFuncName, queryString, args); err != nil {
		return err
	}

	d.SetId(queryString)

	return nil
}

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
