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
			"kiteURL": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
			"vagrantFile": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

var klientFuncName = "vagrant.build"

// resourceMachineCreate creates a new vagrant machine in remote klient host
func resourceMachineCreate(d *schema.ResourceData, meta interface{}) error {
	c, err := NewClient()
	if err != nil {
		return err
	}
	defer c.Close()

	queryString := d.Get("kiteURL").(string)
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

	vagrantFile := d.Get("vagrantFile").(string)

	_, err = klientRef.Client.Tell(klientFuncName, vagrantFile)
	if err != nil {
		return err
	}

	d.SetId(queryString)

	return nil
}

func resourceMachineNoop(d *schema.ResourceData, meta interface{}) error { return nil }
