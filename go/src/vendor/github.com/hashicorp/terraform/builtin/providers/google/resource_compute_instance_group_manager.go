package google

import (
	"fmt"
	"log"
	"strings"

	"google.golang.org/api/compute/v1"
	"google.golang.org/api/googleapi"

	"github.com/hashicorp/terraform/helper/schema"
)

func resourceComputeInstanceGroupManager() *schema.Resource {
	return &schema.Resource{
		Create: resourceComputeInstanceGroupManagerCreate,
		Read:   resourceComputeInstanceGroupManagerRead,
		Update: resourceComputeInstanceGroupManagerUpdate,
		Delete: resourceComputeInstanceGroupManagerDelete,

		Schema: map[string]*schema.Schema{
			"base_instance_name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"instance_template": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"zone": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"fingerprint": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"instance_group": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"named_port": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
					},
				},
			},

			"project": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"self_link": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"update_strategy": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Default:  "RESTART",
			},

			"target_pools": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Set:      schema.HashString,
			},

			"target_size": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
				Optional: true,
			},
		},
	}
}

func getNamedPorts(nps []interface{}) []*compute.NamedPort {
	namedPorts := make([]*compute.NamedPort, 0, len(nps))
	for _, v := range nps {
		np := v.(map[string]interface{})
		namedPorts = append(namedPorts, &compute.NamedPort{
			Name: np["name"].(string),
			Port: int64(np["port"].(int)),
		})
	}
	return namedPorts
}

func resourceComputeInstanceGroupManagerCreate(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)

	project, err := getProject(d, config)
	if err != nil {
		return err
	}

	// Get group size, default to 1 if not given
	var target_size int64 = 1
	if v, ok := d.GetOk("target_size"); ok {
		target_size = int64(v.(int))
	}

	// Build the parameter
	manager := &compute.InstanceGroupManager{
		Name:             d.Get("name").(string),
		BaseInstanceName: d.Get("base_instance_name").(string),
		InstanceTemplate: d.Get("instance_template").(string),
		TargetSize:       target_size,
	}

	// Set optional fields
	if v, ok := d.GetOk("description"); ok {
		manager.Description = v.(string)
	}

	if v, ok := d.GetOk("named_port"); ok {
		manager.NamedPorts = getNamedPorts(v.([]interface{}))
	}

	if attr := d.Get("target_pools").(*schema.Set); attr.Len() > 0 {
		var s []string
		for _, v := range attr.List() {
			s = append(s, v.(string))
		}
		manager.TargetPools = s
	}

	updateStrategy := d.Get("update_strategy").(string)
	if !(updateStrategy == "NONE" || updateStrategy == "RESTART") {
		return fmt.Errorf("Update strategy must be \"NONE\" or \"RESTART\"")
	}

	log.Printf("[DEBUG] InstanceGroupManager insert request: %#v", manager)
	op, err := config.clientCompute.InstanceGroupManagers.Insert(
		project, d.Get("zone").(string), manager).Do()
	if err != nil {
		return fmt.Errorf("Error creating InstanceGroupManager: %s", err)
	}

	// It probably maybe worked, so store the ID now
	d.SetId(manager.Name)

	// Wait for the operation to complete
	err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Creating InstanceGroupManager")
	if err != nil {
		return err
	}

	return resourceComputeInstanceGroupManagerRead(d, meta)
}

func resourceComputeInstanceGroupManagerRead(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)

	project, err := getProject(d, config)
	if err != nil {
		return err
	}

	manager, err := config.clientCompute.InstanceGroupManagers.Get(
		project, d.Get("zone").(string), d.Id()).Do()
	if err != nil {
		if gerr, ok := err.(*googleapi.Error); ok && gerr.Code == 404 {
			log.Printf("[WARN] Removing Instance Group Manager %q because it's gone", d.Get("name").(string))
			// The resource doesn't exist anymore
			d.SetId("")

			return nil
		}

		return fmt.Errorf("Error reading instance group manager: %s", err)
	}

	// Set computed fields
	d.Set("named_port", manager.NamedPorts)
	d.Set("fingerprint", manager.Fingerprint)
	d.Set("instance_group", manager.InstanceGroup)
	d.Set("target_size", manager.TargetSize)
	d.Set("self_link", manager.SelfLink)

	return nil
}
func resourceComputeInstanceGroupManagerUpdate(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)

	project, err := getProject(d, config)
	if err != nil {
		return err
	}

	d.Partial(true)

	// If target_pools changes then update
	if d.HasChange("target_pools") {
		var targetPools []string
		if attr := d.Get("target_pools").(*schema.Set); attr.Len() > 0 {
			for _, v := range attr.List() {
				targetPools = append(targetPools, v.(string))
			}
		}

		// Build the parameter
		setTargetPools := &compute.InstanceGroupManagersSetTargetPoolsRequest{
			Fingerprint: d.Get("fingerprint").(string),
			TargetPools: targetPools,
		}

		op, err := config.clientCompute.InstanceGroupManagers.SetTargetPools(
			project, d.Get("zone").(string), d.Id(), setTargetPools).Do()
		if err != nil {
			return fmt.Errorf("Error updating InstanceGroupManager: %s", err)
		}

		// Wait for the operation to complete
		err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Updating InstanceGroupManager")
		if err != nil {
			return err
		}

		d.SetPartial("target_pools")
	}

	// If instance_template changes then update
	if d.HasChange("instance_template") {
		// Build the parameter
		setInstanceTemplate := &compute.InstanceGroupManagersSetInstanceTemplateRequest{
			InstanceTemplate: d.Get("instance_template").(string),
		}

		op, err := config.clientCompute.InstanceGroupManagers.SetInstanceTemplate(
			project, d.Get("zone").(string), d.Id(), setInstanceTemplate).Do()
		if err != nil {
			return fmt.Errorf("Error updating InstanceGroupManager: %s", err)
		}

		// Wait for the operation to complete
		err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Updating InstanceGroupManager")
		if err != nil {
			return err
		}

		if d.Get("update_strategy").(string) == "RESTART" {
			managedInstances, err := config.clientCompute.InstanceGroupManagers.ListManagedInstances(
				project, d.Get("zone").(string), d.Id()).Do()

			managedInstanceCount := len(managedInstances.ManagedInstances)
			instances := make([]string, managedInstanceCount)
			for i, v := range managedInstances.ManagedInstances {
				instances[i] = v.Instance
			}

			recreateInstances := &compute.InstanceGroupManagersRecreateInstancesRequest{
				Instances: instances,
			}

			op, err = config.clientCompute.InstanceGroupManagers.RecreateInstances(
				project, d.Get("zone").(string), d.Id(), recreateInstances).Do()

			if err != nil {
				return fmt.Errorf("Error restarting instance group managers instances: %s", err)
			}

			// Wait for the operation to complete
			err = computeOperationWaitZoneTime(config, op, d.Get("zone").(string),
				managedInstanceCount*4, "Restarting InstanceGroupManagers instances")
			if err != nil {
				return err
			}
		}

		d.SetPartial("instance_template")
	}

	// If named_port changes then update:
	if d.HasChange("named_port") {

		// Build the parameters for a "SetNamedPorts" request:
		namedPorts := getNamedPorts(d.Get("named_port").([]interface{}))
		setNamedPorts := &compute.InstanceGroupsSetNamedPortsRequest{
			NamedPorts: namedPorts,
		}

		// Make the request:
		op, err := config.clientCompute.InstanceGroups.SetNamedPorts(
			project, d.Get("zone").(string), d.Id(), setNamedPorts).Do()
		if err != nil {
			return fmt.Errorf("Error updating InstanceGroupManager: %s", err)
		}

		// Wait for the operation to complete:
		err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Updating InstanceGroupManager")
		if err != nil {
			return err
		}

		d.SetPartial("named_port")
	}

	// If size changes trigger a resize
	if d.HasChange("target_size") {
		if v, ok := d.GetOk("target_size"); ok {
			// Only do anything if the new size is set
			target_size := int64(v.(int))

			op, err := config.clientCompute.InstanceGroupManagers.Resize(
				project, d.Get("zone").(string), d.Id(), target_size).Do()
			if err != nil {
				return fmt.Errorf("Error updating InstanceGroupManager: %s", err)
			}

			// Wait for the operation to complete
			err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Updating InstanceGroupManager")
			if err != nil {
				return err
			}
		}

		d.SetPartial("target_size")
	}

	d.Partial(false)

	return resourceComputeInstanceGroupManagerRead(d, meta)
}

func resourceComputeInstanceGroupManagerDelete(d *schema.ResourceData, meta interface{}) error {
	config := meta.(*Config)

	project, err := getProject(d, config)
	if err != nil {
		return err
	}

	zone := d.Get("zone").(string)
	op, err := config.clientCompute.InstanceGroupManagers.Delete(project, zone, d.Id()).Do()
	if err != nil {
		return fmt.Errorf("Error deleting instance group manager: %s", err)
	}

	currentSize := int64(d.Get("target_size").(int))

	// Wait for the operation to complete
	err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Deleting InstanceGroupManager")

	for err != nil && currentSize > 0 {
		if !strings.Contains(err.Error(), "timeout") {
			return err
		}

		instanceGroup, err := config.clientCompute.InstanceGroups.Get(
			project, d.Get("zone").(string), d.Id()).Do()

		if err != nil {
			return fmt.Errorf("Error getting instance group size: %s", err)
		}

		if instanceGroup.Size >= currentSize {
			return fmt.Errorf("Error, instance group isn't shrinking during delete")
		}

		log.Printf("[INFO] timeout occured, but instance group is shrinking (%d < %d)", instanceGroup.Size, currentSize)

		currentSize = instanceGroup.Size

		err = computeOperationWaitZone(config, op, d.Get("zone").(string), "Deleting InstanceGroupManager")
	}

	d.SetId("")
	return nil
}
