package cloudstack

import (
	"fmt"
	"strings"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/xanzy/go-cloudstack/cloudstack"
)

func resourceCloudStackDisk() *schema.Resource {
	return &schema.Resource{
		Create: resourceCloudStackDiskCreate,
		Read:   resourceCloudStackDiskRead,
		Update: resourceCloudStackDiskUpdate,
		Delete: resourceCloudStackDiskDelete,

		Schema: map[string]*schema.Schema{
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"attach": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
			},

			"device": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"disk_offering": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"size": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				Computed: true,
			},

			"shrink_ok": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
			},

			"virtual_machine": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"zone": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
		},
	}
}

func resourceCloudStackDiskCreate(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)
	d.Partial(true)

	name := d.Get("name").(string)

	// Create a new parameter struct
	p := cs.Volume.NewCreateVolumeParams(name)

	// Retrieve the disk_offering UUID
	diskofferingid, e := retrieveUUID(cs, "disk_offering", d.Get("disk_offering").(string))
	if e != nil {
		return e.Error()
	}
	// Set the disk_offering UUID
	p.SetDiskofferingid(diskofferingid)

	if d.Get("size").(int) != 0 {
		// Set the volume size
		p.SetSize(int64(d.Get("size").(int)))
	}

	// Retrieve the zone UUID
	zoneid, e := retrieveUUID(cs, "zone", d.Get("zone").(string))
	if e != nil {
		return e.Error()
	}
	// Set the zone ID
	p.SetZoneid(zoneid)

	// Create the new volume
	r, err := cs.Volume.CreateVolume(p)
	if err != nil {
		return fmt.Errorf("Error creating the new disk %s: %s", name, err)
	}

	// Set the volume UUID and partials
	d.SetId(r.Id)
	d.SetPartial("name")
	d.SetPartial("device")
	d.SetPartial("disk_offering")
	d.SetPartial("size")
	d.SetPartial("virtual_machine")
	d.SetPartial("zone")

	if d.Get("attach").(bool) {
		err := resourceCloudStackDiskAttach(d, meta)
		if err != nil {
			return fmt.Errorf("Error attaching the new disk %s to virtual machine: %s", name, err)
		}

		// Set the additional partial
		d.SetPartial("attach")
	}

	d.Partial(false)
	return resourceCloudStackDiskRead(d, meta)
}

func resourceCloudStackDiskRead(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Get the volume details
	v, count, err := cs.Volume.GetVolumeByID(d.Id())
	if err != nil {
		if count == 0 {
			d.SetId("")
			return nil
		}

		return err
	}

	d.Set("name", v.Name)
	d.Set("attach", v.Attached != "")           // If attached this will contain a timestamp when attached
	d.Set("size", int(v.Size/(1024*1024*1024))) // Needed to get GB's again

	setValueOrUUID(d, "disk_offering", v.Diskofferingname, v.Diskofferingid)
	setValueOrUUID(d, "zone", v.Zonename, v.Zoneid)

	if v.Attached != "" {
		// Get the virtual machine details
		vm, _, err := cs.VirtualMachine.GetVirtualMachineByID(v.Virtualmachineid)
		if err != nil {
			return err
		}

		// Get the guest OS type details
		os, _, err := cs.GuestOS.GetOsTypeByID(vm.Guestosid)
		if err != nil {
			return err
		}

		// Get the guest OS category details
		c, _, err := cs.GuestOS.GetOsCategoryByID(os.Oscategoryid)
		if err != nil {
			return err
		}

		d.Set("device", retrieveDeviceName(v.Deviceid, c.Name))
		d.Set("virtual_machine", v.Vmname)
	}

	return nil
}

func resourceCloudStackDiskUpdate(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)
	d.Partial(true)

	name := d.Get("name").(string)

	if d.HasChange("disk_offering") || d.HasChange("size") {
		// Detach the volume (re-attach is done at the end of this function)
		if err := resourceCloudStackDiskDetach(d, meta); err != nil {
			return fmt.Errorf("Error detaching disk %s from virtual machine: %s", name, err)
		}

		// Create a new parameter struct
		p := cs.Volume.NewResizeVolumeParams(d.Id())

		// Retrieve the disk_offering UUID
		diskofferingid, e := retrieveUUID(cs, "disk_offering", d.Get("disk_offering").(string))
		if e != nil {
			return e.Error()
		}

		// Set the disk_offering UUID
		p.SetDiskofferingid(diskofferingid)

		if d.Get("size").(int) != 0 {
			// Set the size
			p.SetSize(int64(d.Get("size").(int)))
		}

		// Set the shrink bit
		p.SetShrinkok(d.Get("shrink_ok").(bool))

		// Change the disk_offering
		r, err := cs.Volume.ResizeVolume(p)
		if err != nil {
			return fmt.Errorf("Error changing disk offering/size for disk %s: %s", name, err)
		}

		// Update the volume UUID and set partials
		d.SetId(r.Id)
		d.SetPartial("disk_offering")
		d.SetPartial("size")
	}

	// If the device changed, just detach here so we can re-attach the
	// volume at the end of this function
	if d.HasChange("device") || d.HasChange("virtual_machine") {
		// Detach the volume
		if err := resourceCloudStackDiskDetach(d, meta); err != nil {
			return fmt.Errorf("Error detaching disk %s from virtual machine: %s", name, err)
		}
	}

	if d.Get("attach").(bool) {
		// Attach the volume
		err := resourceCloudStackDiskAttach(d, meta)
		if err != nil {
			return fmt.Errorf("Error attaching disk %s to virtual machine: %s", name, err)
		}

		// Set the additional partials
		d.SetPartial("attach")
		d.SetPartial("device")
		d.SetPartial("virtual_machine")
	} else {
		// Detach the volume
		if err := resourceCloudStackDiskDetach(d, meta); err != nil {
			return fmt.Errorf("Error detaching disk %s from virtual machine: %s", name, err)
		}
	}

	d.Partial(false)
	return resourceCloudStackDiskRead(d, meta)
}

func resourceCloudStackDiskDelete(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Detach the volume
	if err := resourceCloudStackDiskDetach(d, meta); err != nil {
		return err
	}

	// Create a new parameter struct
	p := cs.Volume.NewDeleteVolumeParams(d.Id())

	// Delete the voluem
	if _, err := cs.Volume.DeleteVolume(p); err != nil {
		// This is a very poor way to be told the UUID does no longer exist :(
		if strings.Contains(err.Error(), fmt.Sprintf(
			"Invalid parameter id value=%s due to incorrect long value format, "+
				"or entity does not exist", d.Id())) {
			return nil
		}

		return err
	}

	return nil
}

func resourceCloudStackDiskAttach(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// First check if the disk isn't already attached
	if attached, err := isAttached(cs, d.Id()); err != nil || attached {
		return err
	}

	// Retrieve the virtual_machine UUID
	virtualmachineid, e := retrieveUUID(cs, "virtual_machine", d.Get("virtual_machine").(string))
	if e != nil {
		return e.Error()
	}

	// Create a new parameter struct
	p := cs.Volume.NewAttachVolumeParams(d.Id(), virtualmachineid)

	if device, ok := d.GetOk("device"); ok {
		// Retrieve the device ID
		deviceid := retrieveDeviceID(device.(string))
		if deviceid == -1 {
			return fmt.Errorf("Device %s is not a valid device", device.(string))
		}

		// Set the device ID
		p.SetDeviceid(deviceid)
	}

	// Attach the new volume
	r, err := cs.Volume.AttachVolume(p)
	if err != nil {
		return err
	}

	d.SetId(r.Id)

	return nil
}

func resourceCloudStackDiskDetach(d *schema.ResourceData, meta interface{}) error {
	cs := meta.(*cloudstack.CloudStackClient)

	// Check if the volume is actually attached, before detaching
	if attached, err := isAttached(cs, d.Id()); err != nil || !attached {
		return err
	}

	// Create a new parameter struct
	p := cs.Volume.NewDetachVolumeParams()

	// Set the volume UUID
	p.SetId(d.Id())

	// Detach the currently attached volume
	if _, err := cs.Volume.DetachVolume(p); err != nil {
		// Retrieve the virtual_machine UUID
		virtualmachineid, e := retrieveUUID(cs, "virtual_machine", d.Get("virtual_machine").(string))
		if e != nil {
			return e.Error()
		}

		// Create a new parameter struct
		pd := cs.VirtualMachine.NewStopVirtualMachineParams(virtualmachineid)

		// Stop the virtual machine in order to be able to detach the disk
		if _, err := cs.VirtualMachine.StopVirtualMachine(pd); err != nil {
			return err
		}

		// Try again to detach the currently attached volume
		if _, err := cs.Volume.DetachVolume(p); err != nil {
			return err
		}

		// Create a new parameter struct
		pu := cs.VirtualMachine.NewStartVirtualMachineParams(virtualmachineid)

		// Start the virtual machine again
		if _, err := cs.VirtualMachine.StartVirtualMachine(pu); err != nil {
			return err
		}
	}

	return nil
}

func isAttached(cs *cloudstack.CloudStackClient, id string) (bool, error) {
	// Get the volume details
	v, _, err := cs.Volume.GetVolumeByID(id)
	if err != nil {
		return false, err
	}

	return v.Attached != "", nil
}

func retrieveDeviceID(device string) int64 {
	switch device {
	case "/dev/xvdb", "D:":
		return 1
	case "/dev/xvdc", "E:":
		return 2
	case "/dev/xvde", "F:":
		return 4
	case "/dev/xvdf", "G:":
		return 5
	case "/dev/xvdg", "H:":
		return 6
	case "/dev/xvdh", "I:":
		return 7
	case "/dev/xvdi", "J:":
		return 8
	case "/dev/xvdj", "K:":
		return 9
	case "/dev/xvdk", "L:":
		return 10
	case "/dev/xvdl", "M:":
		return 11
	case "/dev/xvdm", "N:":
		return 12
	case "/dev/xvdn", "O:":
		return 13
	case "/dev/xvdo", "P:":
		return 14
	case "/dev/xvdp", "Q:":
		return 15
	default:
		return -1
	}
}

func retrieveDeviceName(device int64, os string) string {
	switch device {
	case 1:
		if os == "Windows" {
			return "D:"
		} else {
			return "/dev/xvdb"
		}
	case 2:
		if os == "Windows" {
			return "E:"
		} else {
			return "/dev/xvdc"
		}
	case 4:
		if os == "Windows" {
			return "F:"
		} else {
			return "/dev/xvde"
		}
	case 5:
		if os == "Windows" {
			return "G:"
		} else {
			return "/dev/xvdf"
		}
	case 6:
		if os == "Windows" {
			return "H:"
		} else {
			return "/dev/xvdg"
		}
	case 7:
		if os == "Windows" {
			return "I:"
		} else {
			return "/dev/xvdh"
		}
	case 8:
		if os == "Windows" {
			return "J:"
		} else {
			return "/dev/xvdi"
		}
	case 9:
		if os == "Windows" {
			return "K:"
		} else {
			return "/dev/xvdj"
		}
	case 10:
		if os == "Windows" {
			return "L:"
		} else {
			return "/dev/xvdk"
		}
	case 11:
		if os == "Windows" {
			return "M:"
		} else {
			return "/dev/xvdl"
		}
	case 12:
		if os == "Windows" {
			return "N:"
		} else {
			return "/dev/xvdm"
		}
	case 13:
		if os == "Windows" {
			return "O:"
		} else {
			return "/dev/xvdn"
		}
	case 14:
		if os == "Windows" {
			return "P:"
		} else {
			return "/dev/xvdo"
		}
	case 15:
		if os == "Windows" {
			return "Q:"
		} else {
			return "/dev/xvdp"
		}
	default:
		return "unknown"
	}
}
