package azure

import (
	"bytes"
	"crypto/sha1"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/management/hostedservice"
	"github.com/Azure/azure-sdk-for-go/management/osimage"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachine"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachineimage"
	"github.com/Azure/azure-sdk-for-go/management/vmutils"
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

const (
	linux                 = "Linux"
	windows               = "Windows"
	storageContainterName = "vhds"
	osDiskBlobNameFormat  = "%s.vhd"
	osDiskBlobStorageURL  = "http://%s.blob.core.windows.net/" + storageContainterName + "/" + osDiskBlobNameFormat
)

func resourceAzureInstance() *schema.Resource {
	return &schema.Resource{
		Create: resourceAzureInstanceCreate,
		Read:   resourceAzureInstanceRead,
		Update: resourceAzureInstanceUpdate,
		Delete: resourceAzureInstanceDelete,

		Schema: map[string]*schema.Schema{
			"name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"hosted_service_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			// in order to prevent an unintentional delete of a containing
			// hosted service in the case the same name are given to both the
			// service and the instance despite their being created separately,
			// we must maintain a flag to definitively denote whether this
			// instance had a hosted service created for it or not:
			"has_dedicated_service": &schema.Schema{
				Type:     schema.TypeBool,
				Computed: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"image": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"size": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"subnet": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"virtual_network": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"storage_service_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"reverse_dns": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"location": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"automatic_updates": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
				ForceNew: true,
			},

			"time_zone": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"username": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"password": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"ssh_key_thumbprint": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"endpoint": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"protocol": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Default:  "tcp",
						},

						"public_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},

						"private_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
					},
				},
				Set: resourceAzureEndpointHash,
			},

			"security_group": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"ip_address": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"vip_address": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"domain_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"domain_username": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"domain_password": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"domain_ou": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"custom_data": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
				StateFunc: func(v interface{}) string {
					if s, ok := v.(string); ok && s != "" {
						hash := sha1.Sum([]byte(s))
						return hex.EncodeToString(hash[:])
					}
					return ""
				},
			},
		},
	}
}

func resourceAzureInstanceCreate(d *schema.ResourceData, meta interface{}) (err error) {
	azureClient := meta.(*Client)
	mc := azureClient.mgmtClient
	hostedServiceClient := azureClient.hostedServiceClient
	vmClient := azureClient.vmClient

	name := d.Get("name").(string)

	// Compute/set the description
	description := d.Get("description").(string)
	if description == "" {
		description = name
	}

	// Retrieve the needed details of the image
	configureForImage, osType, err := retrieveImageDetails(
		meta,
		d.Get("image").(string),
		name,
		d.Get("storage_service_name").(string),
	)
	if err != nil {
		return err
	}

	// Verify if we have all required parameters
	if err := verifyInstanceParameters(d, osType); err != nil {
		return err
	}

	var hostedServiceName string
	// check if hosted service name parameter was given:
	if serviceName, ok := d.GetOk("hosted_service_name"); !ok {
		// if not provided; just use the name of the instance to create a new one:
		hostedServiceName = name
		d.Set("hosted_service_name", hostedServiceName)
		d.Set("has_dedicated_service", true)

		p := hostedservice.CreateHostedServiceParameters{
			ServiceName:    hostedServiceName,
			Label:          base64.StdEncoding.EncodeToString([]byte(name)),
			Description:    fmt.Sprintf("Cloud Service created automatically for instance %s", name),
			Location:       d.Get("location").(string),
			ReverseDNSFqdn: d.Get("reverse_dns").(string),
		}

		log.Printf("[DEBUG] Creating Cloud Service for instance: %s", name)
		err = hostedServiceClient.CreateHostedService(p)
		if err != nil {
			return fmt.Errorf("Error creating Cloud Service for instance %s: %s", name, err)
		}
	} else {
		// else; use the provided hosted service name:
		hostedServiceName = serviceName.(string)
	}

	// Create a new role for the instance
	role := vmutils.NewVMConfiguration(name, d.Get("size").(string))

	log.Printf("[DEBUG] Configuring deployment from image...")
	err = configureForImage(&role)
	if err != nil {
		return fmt.Errorf("Error configuring the deployment for %s: %s", name, err)
	}

	var customData string
	if data, ok := d.GetOk("custom_data"); ok {
		data := data.(string)

		// Ensure the custom_data is not double-encoded.
		if _, err := base64.StdEncoding.DecodeString(data); err != nil {
			customData = base64.StdEncoding.EncodeToString([]byte(data))
		} else {
			customData = data
		}
	}

	if osType == linux {
		// This is pretty ugly, but the Azure SDK leaves me no other choice...
		if tp, ok := d.GetOk("ssh_key_thumbprint"); ok {
			err = vmutils.ConfigureForLinux(
				&role,
				name,
				d.Get("username").(string),
				d.Get("password").(string),
				tp.(string),
			)
		} else {
			err = vmutils.ConfigureForLinux(
				&role,
				name,
				d.Get("username").(string),
				d.Get("password").(string),
			)
		}
		if err != nil {
			return fmt.Errorf("Error configuring %s for Linux: %s", name, err)
		}

		if customData != "" {
			err = vmutils.ConfigureWithCustomDataForLinux(&role, customData)
			if err != nil {
				return fmt.Errorf("Error configuring custom data for %s: %s", name, err)
			}
		}
	}

	if osType == windows {
		err = vmutils.ConfigureForWindows(
			&role,
			name,
			d.Get("username").(string),
			d.Get("password").(string),
			d.Get("automatic_updates").(bool),
			d.Get("time_zone").(string),
		)
		if err != nil {
			return fmt.Errorf("Error configuring %s for Windows: %s", name, err)
		}

		if domain_name, ok := d.GetOk("domain_name"); ok {
			err = vmutils.ConfigureWindowsToJoinDomain(
				&role,
				d.Get("domain_username").(string),
				d.Get("domain_password").(string),
				domain_name.(string),
				d.Get("domain_ou").(string),
			)
			if err != nil {
				return fmt.Errorf("Error configuring %s for WindowsToJoinDomain: %s", name, err)
			}
		}

		if customData != "" {
			err = vmutils.ConfigureWithCustomDataForWindows(&role, customData)
			if err != nil {
				return fmt.Errorf("Error configuring custom data for %s: %s", name, err)
			}
		}
	}

	if s := d.Get("endpoint").(*schema.Set); s.Len() > 0 {
		for _, v := range s.List() {
			m := v.(map[string]interface{})
			err := vmutils.ConfigureWithExternalPort(
				&role,
				m["name"].(string),
				m["private_port"].(int),
				m["public_port"].(int),
				endpointProtocol(m["protocol"].(string)),
			)
			if err != nil {
				return fmt.Errorf(
					"Error adding endpoint %s for instance %s: %s", m["name"].(string), name, err)
			}
		}
	}

	if subnet, ok := d.GetOk("subnet"); ok {
		err = vmutils.ConfigureWithSubnet(&role, subnet.(string))
		if err != nil {
			return fmt.Errorf(
				"Error associating subnet %s with instance %s: %s", d.Get("subnet").(string), name, err)
		}
	}

	if sg, ok := d.GetOk("security_group"); ok {
		err = vmutils.ConfigureWithSecurityGroup(&role, sg.(string))
		if err != nil {
			return fmt.Errorf(
				"Error associating security group %s with instance %s: %s", sg.(string), name, err)
		}
	}

	log.Printf("[DEBUG] Checking if this cloud service already has a deployment...")
	existingDeploymentName, err := vmClient.GetDeploymentName(hostedServiceName)
	if err != nil {
		return fmt.Errorf("Error creating instance %s while checking whether cloud service %s has existing deployments: %s", name, hostedServiceName, err)
	}

	// existingDeploymentName empty means this is the first VM being attached to this cloud service
	// we have to call the CreateDeployment(...) method
	if existingDeploymentName == "" {
		options := virtualmachine.CreateDeploymentOptions{
			VirtualNetworkName: d.Get("virtual_network").(string),
		}

		log.Printf("[DEBUG] Creating the new VM instance along with a new deployment...")
		req, err := vmClient.CreateDeployment(role, hostedServiceName, options)
		if err != nil {
			return fmt.Errorf("Error creating instance %s: %s", name, err)
		}

		log.Printf("[DEBUG] Waiting for the new instance to be created...")
		if err := mc.WaitForOperation(req, nil); err != nil {
			return fmt.Errorf("Error waiting for instance %s to be created: %s", name, err)
		}

		// existingDeploymentName has a value means this cloud service already has other VM-s, we will have
		// to call AddRole(...) to add this VM to the existing deployment under this cloud service
	} else {
		log.Printf("[DEBUG] Adding the new VM instance to an existing deployment...")
		addRoleOpId, err := vmClient.AddRole(hostedServiceName, existingDeploymentName, role)
		if err != nil {
			return fmt.Errorf("Error creating and adding new instance %s to cloud service %s with existing deployment %s: %s", name, hostedServiceName, existingDeploymentName, err)
		}

		log.Printf("[DEBUG] Waiting for the new instance to be created and added to the existing cloud service and deployment...")
		if err := mc.WaitForOperation(addRoleOpId, nil); err != nil {
			return fmt.Errorf("Error waiting for instance %s to be created and added to cloud service %s with existing deployment %s: %s", name, hostedServiceName, existingDeploymentName, err)
		}
	}

	d.SetId(name)

	return resourceAzureInstanceRead(d, meta)
}

func resourceAzureInstanceRead(d *schema.ResourceData, meta interface{}) error {
	azureClient := meta.(*Client)
	hostedServiceClient := azureClient.hostedServiceClient
	vmClient := azureClient.vmClient

	name := d.Get("name").(string)

	// check if the instance belongs to an independent hosted service
	// or it had one created for it.
	var hostedServiceName string
	if serviceName, ok := d.GetOk("hosted_service_name"); ok {
		// if independent; use that hosted service name:
		hostedServiceName = serviceName.(string)
	} else {
		// else; suppose it's the instance's name:
		hostedServiceName = name
	}

	log.Printf("[DEBUG] Retrieving Cloud Service for instance: %s", name)
	cs, err := hostedServiceClient.GetHostedService(hostedServiceName)
	if err != nil {
		return fmt.Errorf("Error retrieving Cloud Service of instance %s (%q): %s", name, hostedServiceName, err)
	}

	d.Set("reverse_dns", cs.ReverseDNSFqdn)
	d.Set("location", cs.Location)

	log.Printf("[DEBUG] Retrieving instance: %s", name)
	deploymentName, err := vmClient.GetDeploymentName(hostedServiceName)
	if err != nil {
		return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to read instance %s: %s", hostedServiceName, name, err)
	}
	if deploymentName == "" {
		return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to read instance %s: No deployment exists!", hostedServiceName, name)
	}
	dpmt, err := vmClient.GetDeployment(hostedServiceName, deploymentName)
	if err != nil {
		return fmt.Errorf("Error retrieving deployment %s while trying to read instance %s: %s", deploymentName, name, err)
	}

	// A cloud service has one or more deployments(in the case of terraform, we will support
	// just one deployment, that in the "Production" deployment slot)
	// Each deployment has one or more Roles. Each Role has one or more Role Instances
	// However, both the RoleList array and RoleInstanceList array are contained as part of DeploymentResponse struct
	// see here: https://msdn.microsoft.com/en-us/library/azure/ee460804.aspx
	// Also notable is that terraform is, until now, for IAAS infrastructure only (as opposed to PAAS web and worker roles)
	// Therefore, the Role-s we create here will have a RoleType field set to "PersistentVMRole"

	if len(dpmt.RoleList) < 1 {
		return fmt.Errorf("Error reading instance %s: RoleList for deployment %s is empty", name, deploymentName)
	}
	if len(dpmt.RoleInstanceList) < 1 {
		return fmt.Errorf("Error reading instance %s: RoleInstanceList for deployment %s is empty", name, deploymentName)
	}

	//roleInst is a pointer that will point to the correct element in the dpmt.RoleInstanceList array
	var roleInst *virtualmachine.RoleInstance = nil
	for i := range dpmt.RoleInstanceList {
		if dpmt.RoleInstanceList[i].InstanceName == name {
			roleInst = &dpmt.RoleInstanceList[i]
			break
		}
	}
	if roleInst == nil {
		return fmt.Errorf("Error reading instance %s: RoleInstanceList does not contain any VM by that name", name)
	}

	//role is a pointer that will point to the correct element in the dpmt.RoleList array
	var role *virtualmachine.Role = nil
	for j := range dpmt.RoleList {
		if dpmt.RoleList[j].RoleName == roleInst.RoleName {
			role = &dpmt.RoleList[j]
			break
		}
	}
	if role == nil {
		return fmt.Errorf("Error reading instance %s: RoleList does not contain any Role by the name %s", name, roleInst.RoleName)
	}

	//Now populate various fields in d from either role or roleInst, whichever makes sense
	d.Set("size", role.RoleSize)
	d.Set("ip_address", roleInst.IPAddress)
	if len(roleInst.InstanceEndpoints) > 0 {
		d.Set("vip_address", roleInst.InstanceEndpoints[0].Vip)
	}

	// Find the network configuration set
	for _, c := range role.ConfigurationSets {
		if c.ConfigurationSetType == virtualmachine.ConfigurationSetTypeNetwork {
			// Create a new set to hold all configured endpoints
			endpoints := &schema.Set{
				F: resourceAzureEndpointHash,
			}

			// Loop through all endpoints
			for _, ep := range c.InputEndpoints {
				endpoint := map[string]interface{}{}

				// Update the values
				endpoint["name"] = ep.Name
				endpoint["protocol"] = string(ep.Protocol)
				endpoint["public_port"] = ep.Port
				endpoint["private_port"] = ep.LocalPort
				endpoints.Add(endpoint)
			}
			d.Set("endpoint", endpoints)

			// Update the subnet
			switch len(c.SubnetNames) {
			case 1:
				d.Set("subnet", c.SubnetNames[0])
			case 0:
				d.Set("subnet", "")
			default:
				return fmt.Errorf("Instance %s has an unexpected number of associated subnets %d", name, len(c.SubnetNames))
			}

			// Update the security group
			d.Set("security_group", c.NetworkSecurityGroup)
		}
	}

	connType := "ssh"
	if role.OSVirtualHardDisk.OS == windows {
		connType = "winrm"
	}

	// Set the connection info for any configured provisioners
	d.SetConnInfo(map[string]string{
		"type":     connType,
		"host":     dpmt.VirtualIPs[0].Address,
		"user":     d.Get("username").(string),
		"password": d.Get("password").(string),
	})

	return nil
}

func resourceAzureInstanceUpdate(d *schema.ResourceData, meta interface{}) error {
	azureClient := meta.(*Client)
	mc := azureClient.mgmtClient
	vmClient := azureClient.vmClient

	// First check if anything we can update changed, and if not just return
	if !d.HasChange("size") && !d.HasChange("endpoint") && !d.HasChange("security_group") {
		return nil
	}

	name := d.Get("name").(string)

	// check if the instance belongs to an independent hosted service
	// or it had one created for it.
	var hostedServiceName string
	if serviceName, ok := d.GetOk("hosted_service_name"); ok {
		// if independent; use that hosted service name:
		hostedServiceName = serviceName.(string)
	} else {
		// else; suppose it's the instance's name:
		hostedServiceName = name
	}

	deploymentName, err := vmClient.GetDeploymentName(hostedServiceName)
	if err != nil {
		return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to update instance %s: %s", hostedServiceName, name, err)
	}
	if deploymentName == "" {
		return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to update instance %s: No deployment exists!", hostedServiceName, name)
	}

	// Get the current role
	role, err := vmClient.GetRole(hostedServiceName, deploymentName, name)
	if err != nil {
		return fmt.Errorf("Error retrieving role of instance %s: %s", name, err)
	}

	// Verify if we have all required parameters
	if err := verifyInstanceParameters(d, role.OSVirtualHardDisk.OS); err != nil {
		return err
	}

	if d.HasChange("size") {
		role.RoleSize = d.Get("size").(string)
	}

	if d.HasChange("endpoint") {
		_, n := d.GetChange("endpoint")

		// Delete the existing endpoints
		for i, c := range role.ConfigurationSets {
			if c.ConfigurationSetType == virtualmachine.ConfigurationSetTypeNetwork {
				c.InputEndpoints = nil
				role.ConfigurationSets[i] = c
			}
		}

		// And add the ones we still want
		if s := n.(*schema.Set); s.Len() > 0 {
			for _, v := range s.List() {
				m := v.(map[string]interface{})
				err := vmutils.ConfigureWithExternalPort(
					role,
					m["name"].(string),
					m["private_port"].(int),
					m["public_port"].(int),
					endpointProtocol(m["protocol"].(string)),
				)
				if err != nil {
					return fmt.Errorf(
						"Error adding endpoint %s for instance %s: %s", m["name"].(string), name, err)
				}
			}
		}
	}

	if d.HasChange("security_group") {
		sg := d.Get("security_group").(string)
		err := vmutils.ConfigureWithSecurityGroup(role, sg)
		if err != nil {
			return fmt.Errorf(
				"Error associating security group %s with instance %s: %s", sg, name, err)
		}
	}

	// Update the adjusted role
	req, err := vmClient.UpdateRole(hostedServiceName, deploymentName, name, *role)
	if err != nil {
		return fmt.Errorf("Error updating role of instance %s: %s", name, err)
	}

	if err := mc.WaitForOperation(req, nil); err != nil {
		return fmt.Errorf(
			"Error waiting for role of instance %s to be updated: %s", name, err)
	}

	return resourceAzureInstanceRead(d, meta)
}

func resourceAzureInstanceDelete(d *schema.ResourceData, meta interface{}) error {
	azureClient := meta.(*Client)
	mc := azureClient.mgmtClient
	vmClient := azureClient.vmClient

	name := d.Get("name").(string)

	// check if the instance belongs to an independent hosted service
	// or it had one created for it.
	var hostedServiceName string
	if serviceName, ok := d.GetOk("hosted_service_name"); ok {
		// if independent; use that hosted service name:
		hostedServiceName = serviceName.(string)
	} else {
		// else; suppose it's the instance's name:
		hostedServiceName = name
	}

	log.Printf("[DEBUG] Deleting instance: %s", name)

	//Note: The logic around "has_dedicated_service" works well in spite of the fact that it was added before the code
	//changes necessray to handle multiple VM-s per cloud service. That is because this internal flag is set ONLY when
	//the cloud service was created along with the VM creation. Therefore, no matter what happened afterwards, it should
	//get destroyed when the VM is getting destroyed.

	// check if the instance had a hosted service created especially for it:
	if d.Get("has_dedicated_service").(bool) {
		// if so; we must delete the associated hosted service as well:
		hostedServiceClient := azureClient.hostedServiceClient
		req, err := hostedServiceClient.DeleteHostedService(hostedServiceName, true)
		if err != nil {
			return fmt.Errorf("Error deleting instance %s: Error deleting hosted service %s: %s", name, hostedServiceName, err)
		}

		// Wait until the hosted service and the instance it contains is deleted:
		if err := mc.WaitForOperation(req, nil); err != nil {
			return fmt.Errorf(
				"Error waiting for instance %s to be deleted: %s", name, err)
		}
	} else {
		// Here, the idea is that we do not delete the entire deployment if there are other
		// VM-s still existing (*after* we delete the current VM). So, first, we call GetDeployment
		// on the deployment name (which we obtain by calling GetDeploymentName) to check if this
		// is the last VM. If yes, we blow away the whole deployment. Else we just call DeleteRole

		// First, call GetDeploymentName so that we can call GetDeployment() with that deployment name
		deploymentName, err := vmClient.GetDeploymentName(hostedServiceName)
		if err != nil {
			return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to delete instance %s: %s", hostedServiceName, name, err)
		}
		if deploymentName == "" {
			return fmt.Errorf("Error retrieving deployment from cloud service %s while trying to delete instance %s: No deployment exists!", hostedServiceName, name)
		}

		// Second, call GetDeployment() to retrieve the whole DeploymentResponse struct, so that we can check RoleInstanceList array's length
		dpmt, err := vmClient.GetDeployment(hostedServiceName, deploymentName)
		if err != nil {
			return fmt.Errorf("Error retrieving deployment %s while trying to delete instance %s: %s", deploymentName, name, err)
		}

		// Third, check RoleInstanceList array's length to determine if this is the last VM in this deployment.
		// If yes, remove the whole deployment. Else, remove just the VM using DeleteRole(...)
		if len(dpmt.RoleInstanceList) == 1 {
			reqID, err := vmClient.DeleteDeployment(hostedServiceName, name)
			if err != nil {
				return fmt.Errorf("Error deleting instance %s off hosted service %s: %s", name, hostedServiceName, err)
			}

			// and wait for the deletion:
			if err := mc.WaitForOperation(reqID, nil); err != nil {
				return fmt.Errorf("Error waiting for intance %s to be deleted off the hosted service %s: %s",
					name, hostedServiceName, err)
			}
		} else {
			// This is not the last VM in the deployment, call DeleteRole
			delRoleOpId, err := vmClient.DeleteRole(hostedServiceName, deploymentName, name, true)
			if err != nil {
				return fmt.Errorf("Error trying to delete instance %s: %s", name, err)
			}

			// Wait for that call to complete
			if err := mc.WaitForOperation(delRoleOpId, nil); err != nil {
				return fmt.Errorf("Error waiting for instance %s to be deleted: %s", name, err)
			}
		}
	}

	log.Printf("[INFO] Waiting for the deletion of instance '%s''s disk blob.", name)

	// in order to avoid `terraform taint`-like scenarios in which the instance
	// is deleted and re-created so fast the previous storage blob which held
	// the image doesn't manage to get deleted (despite it being in a
	// 'deleting' state) and a lease conflict occurs over it, we must ensure
	// the blob got completely deleted as well:
	storName := d.Get("storage_service_name").(string)
	blobClient, err := azureClient.getStorageServiceBlobClient(storName)
	if err != nil {
		return err
	}

	err = resource.Retry(15*time.Minute, func() *resource.RetryError {
		container := blobClient.GetContainerReference(storageContainterName)
		blobName := fmt.Sprintf(osDiskBlobNameFormat, name)
		blob := container.GetBlobReference(blobName)
		exists, err := blob.Exists()
		if err != nil {
			return resource.NonRetryableError(err)
		}

		if exists {
			return resource.RetryableError(
				fmt.Errorf("Instance '%s''s disk storage blob still exists.", name))
		}

		return nil
	})

	return err
}

func resourceAzureEndpointHash(v interface{}) int {
	var buf bytes.Buffer
	m := v.(map[string]interface{})
	buf.WriteString(fmt.Sprintf("%s-", m["name"].(string)))
	buf.WriteString(fmt.Sprintf("%s-", m["protocol"].(string)))
	buf.WriteString(fmt.Sprintf("%d-", m["public_port"].(int)))
	buf.WriteString(fmt.Sprintf("%d-", m["private_port"].(int)))

	return hashcode.String(buf.String())
}

func retrieveImageDetails(
	meta interface{},
	label string,
	name string,
	storage string) (func(*virtualmachine.Role) error, string, error) {

	azureClient := meta.(*Client)
	vmImageClient := azureClient.vmImageClient
	osImageClient := azureClient.osImageClient

	configureForImage, osType, VMLabels, err := retrieveVMImageDetails(vmImageClient, label)
	if err == nil {
		return configureForImage, osType, nil
	}

	configureForImage, osType, OSLabels, err := retrieveOSImageDetails(osImageClient, label, name, storage)
	if err == nil {
		return configureForImage, osType, nil
	}

	if err == PlatformStorageError {
		return nil, "", err
	}

	return nil, "", fmt.Errorf("Could not find image with label '%s'. Available images are: %s",
		label, strings.Join(append(VMLabels, OSLabels...), ", "))
}

func retrieveVMImageDetails(
	vmImageClient virtualmachineimage.Client,
	label string) (func(*virtualmachine.Role) error, string, []string, error) {
	imgs, err := vmImageClient.ListVirtualMachineImages(virtualmachineimage.ListParameters{})
	if err != nil {
		return nil, "", nil, fmt.Errorf("Error retrieving image details: %s", err)
	}

	var labels []string
	for _, img := range imgs.VMImages {
		if img.Label == label {
			if img.OSDiskConfiguration.OS != linux && img.OSDiskConfiguration.OS != windows {
				return nil, "", nil, fmt.Errorf("Unsupported image OS: %s", img.OSDiskConfiguration.OS)
			}

			configureForImage := func(role *virtualmachine.Role) error {
				return vmutils.ConfigureDeploymentFromPublishedVMImage(
					role,
					img.Name,
					"",
					true,
				)
			}

			return configureForImage, img.OSDiskConfiguration.OS, nil, nil
		}

		labels = append(labels, img.Label)
	}

	return nil, "", labels, fmt.Errorf("Could not find image with label '%s'", label)
}

func retrieveOSImageDetails(
	osImageClient osimage.OSImageClient,
	label string,
	name string,
	storage string) (func(*virtualmachine.Role) error, string, []string, error) {

	imgs, err := osImageClient.ListOSImages()
	if err != nil {
		return nil, "", nil, fmt.Errorf("Error retrieving image details: %s", err)
	}

	var labels []string
	for _, img := range imgs.OSImages {
		if img.Label == label {
			if img.OS != linux && img.OS != windows {
				return nil, "", nil, fmt.Errorf("Unsupported image OS: %s", img.OS)
			}
			if img.MediaLink == "" {
				if storage == "" {
					return nil, "", nil, PlatformStorageError
				}
				img.MediaLink = fmt.Sprintf(osDiskBlobStorageURL, storage, name)
			}

			configureForImage := func(role *virtualmachine.Role) error {
				return vmutils.ConfigureDeploymentFromPlatformImage(
					role,
					img.Name,
					img.MediaLink,
					label,
				)
			}

			return configureForImage, img.OS, nil, nil
		}

		labels = append(labels, img.Label)
	}

	return nil, "", labels, fmt.Errorf("Could not find image with label '%s'", label)
}

func endpointProtocol(p string) virtualmachine.InputEndpointProtocol {
	if p == "tcp" {
		return virtualmachine.InputEndpointProtocolTCP
	}

	return virtualmachine.InputEndpointProtocolUDP
}

func verifyInstanceParameters(d *schema.ResourceData, osType string) error {
	if osType == linux {
		_, pass := d.GetOk("password")
		_, key := d.GetOk("ssh_key_thumbprint")

		if !pass && !key {
			return fmt.Errorf(
				"You must supply a 'password' and/or a 'ssh_key_thumbprint' when using a Linux image")
		}
	}

	if osType == windows {
		if _, ok := d.GetOk("password"); !ok {
			return fmt.Errorf("You must supply a 'password' when using a Windows image")
		}

		if _, ok := d.GetOk("time_zone"); !ok {
			return fmt.Errorf("You must supply a 'time_zone' when using a Windows image")
		}
	}

	if _, ok := d.GetOk("subnet"); ok {
		if _, ok := d.GetOk("virtual_network"); !ok {
			return fmt.Errorf("You must also supply a 'virtual_network' when supplying a 'subnet'")
		}
	}

	if s := d.Get("endpoint").(*schema.Set); s.Len() > 0 {
		for _, v := range s.List() {
			protocol := v.(map[string]interface{})["protocol"].(string)

			if protocol != "tcp" && protocol != "udp" {
				return fmt.Errorf(
					"Invalid endpoint protocol %s! Valid options are 'tcp' and 'udp'.", protocol)
			}
		}
	}

	return nil
}
