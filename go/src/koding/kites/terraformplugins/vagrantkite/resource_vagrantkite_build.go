package vagrantkite

import (
	"errors"
	"koding/kites/kloud/klient"
	"log"
	"net"
	"net/url"
	"time"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

// this signals the end of a watch command when we listen from Klient
const magicEnd = "guCnvNVedAQT8DiNpcP3pVqzseJvLY"

type vagrantCreateReq struct {
	FilePath      string
	ProvisionData string
	Hostname      string
	Box           string
	Memory        int
	Cpus          int
	CustomScript  string
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
			// Required configuration files
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
			"provisionData": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				Description: "JSON data encoded as base64 needed for provisioning the Vagrant box",
			},

			// Optional configuration fields
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
			"customScript": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Custom script to be executed inside the Vagrant box after the main provisioning is finished.",
			},

			"registerURL": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Register URL of the klient inside the Vagrant box",
			},
			"kontrolURL": &schema.Schema{
				Type:        schema.TypeString,
				Optional:    true,
				Description: "Kontrol URL of the klient inside the Vagrant box",
			},

			// Computes fields
			"klientHostURL": &schema.Schema{
				Type:        schema.TypeString,
				Computed:    true,
				Description: "URL of the Klient inside the host machine where the Vagrant box residues",
			},
			"klientGuestURL": &schema.Schema{
				Type:        schema.TypeString,
				Computed:    true,
				Description: "URL of the Klient inside the guest machine where the Vagrant box residues",
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
		FilePath:      d.Get("filePath").(string),
		ProvisionData: d.Get("provisionData").(string),
		Box:           d.Get("box").(string),
		Hostname:      d.Get("hostname").(string),
		Memory:        d.Get("memory").(int),
		Cpus:          d.Get("cpus").(int),
		CustomScript:  d.Get("customScript").(string),
	}

	resp, err := klientRef.Client.Tell("vagrant.create", args)
	if err != nil {
		return err
	}

	// the "vagrant.create" method returns the same paramaters back. However if
	// we previously passed empty options, such as hostname, it returns the
	// final result
	var result vagrantCreateReq
	if err := resp.Unmarshal(&result); err != nil {
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

	select {
	case <-done:
	case <-time.After(time.Minute * 10):
		return errors.New("Vagrant build took to much time(10 minutes). Please try again")
	}

	// Klient runs on 56789 inside the machine, but Vagrant exposes it as 56790
	// so it doesn't collide with the Klient inside the Host machine. So change
	// the port, but keep the Host the same.
	u, err := url.Parse(klientRef.URL())
	if err != nil {
		return err
	}

	host, _, err := net.SplitHostPort(u.Host)
	if err != nil {
		return err
	}

	u.Host = net.JoinHostPort(host, "56790")

	d.SetId(queryString)
	d.Set("klientHostURL", klientRef.URL())
	d.Set("klientGuestURL", u.String())
	d.Set("hostname", result.Hostname)
	d.Set("box", result.Box)
	d.Set("cpus", result.Cpus)
	d.Set("memory", result.Memory)
	return nil
}

func resourceMachineNoop(d *schema.ResourceData, meta interface{}) error { return nil }
