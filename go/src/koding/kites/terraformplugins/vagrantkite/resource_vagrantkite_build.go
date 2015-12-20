package vagrantkite

import (
	"koding/kites/kloud/klient"
	"log"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

// this signals the end of a watch command when we listen from Klient
const magicEnd = "guCnvNVedAQT8DiNpcP3pVqzseJvLY"

type vagrantCreateReq struct {
	FilePath string
	Hostname string
	Box      string
	Memory   int
	Cpus     int
}

type vagrantUpReq struct {
	FilePath string
	Watch    dnode.Function
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
	// TODO(arslan): cache the client, it reads from kite.key every single time
	// it tries to populate the config
	c, err := NewClient()
	if err != nil {
		return err
	}
	defer c.Close()

	queryString := d.Get("queryString").(string)

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

	args := &vagrantCreateReq{
		FilePath: d.Get("filePath").(string),
		Box:      d.Get("box").(string),
		Hostname: d.Get("hostname").(string),
		Memory:   d.Get("memory").(int),
		Cpus:     d.Get("cpus").(int),
	}

	if _, err = klientRef.Client.Tell("vagrant.create", args); err != nil {
		return err
	}

	done := make(chan bool)

	watch := dnode.Callback(func(r *dnode.Partial) {
		msg := r.One().MustString()
		log.Println("[DEBUG] Vagrant up msg:", msg)
		if msg == magicEnd {
			close(done)
		}
	})

	upArgs := &vagrantUpReq{
		FilePath: d.Get("filePath").(string),
		Watch:    watch,
	}

	if _, err = klientRef.Client.Tell("vagrant.up", upArgs); err != nil {
		return err
	}

	// TODO(arslan): timeout with a select statement
	<-done

	d.SetId(queryString)

	return nil
}

func resourceMachineNoop(d *schema.ResourceData, meta interface{}) error { return nil }
