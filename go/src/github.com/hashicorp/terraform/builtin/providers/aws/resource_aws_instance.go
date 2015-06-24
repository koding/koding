package aws

import (
	"bytes"
	"crypto/sha1"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/awsutil"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsInstance() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsInstanceCreate,
		Read:   resourceAwsInstanceRead,
		Update: resourceAwsInstanceUpdate,
		Delete: resourceAwsInstanceDelete,

		SchemaVersion: 1,
		MigrateState:  resourceAwsInstanceMigrateState,

		Schema: map[string]*schema.Schema{
			"ami": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"associate_public_ip_address": &schema.Schema{
				Type:     schema.TypeBool,
				ForceNew: true,
				Optional: true,
			},

			"availability_zone": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"placement_group": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"instance_type": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"key_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
				Computed: true,
			},

			"subnet_id": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"private_ip": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
				Computed: true,
			},

			"source_dest_check": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  true,
			},

			"user_data": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
				StateFunc: func(v interface{}) string {
					switch v.(type) {
					case string:
						hash := sha1.Sum([]byte(v.(string)))
						return hex.EncodeToString(hash[:])
					default:
						return ""
					}
				},
			},

			"security_groups": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Set:      schema.HashString,
			},

			"vpc_security_group_ids": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
				Set: func(v interface{}) int {
					return hashcode.String(v.(string))
				},
			},

			"public_dns": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"public_ip": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"private_dns": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},

			"ebs_optimized": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
			},

			"disable_api_termination": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
			},

			"iam_instance_profile": &schema.Schema{
				Type:     schema.TypeString,
				ForceNew: true,
				Optional: true,
			},

			"tenancy": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"tags": tagsSchema(),

			"block_device": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				Removed:  "Split out into three sub-types; see Changelog and Docs",
			},

			"ebs_block_device": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"delete_on_termination": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Default:  true,
							ForceNew: true,
						},

						"device_name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"encrypted": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"iops": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"snapshot_id": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"volume_size": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"volume_type": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},
					},
				},
				Set: func(v interface{}) int {
					var buf bytes.Buffer
					m := v.(map[string]interface{})
					buf.WriteString(fmt.Sprintf("%s-", m["device_name"].(string)))
					buf.WriteString(fmt.Sprintf("%s-", m["snapshot_id"].(string)))
					return hashcode.String(buf.String())
				},
			},

			"ephemeral_block_device": &schema.Schema{
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"device_name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"virtual_name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
					},
				},
				Set: func(v interface{}) int {
					var buf bytes.Buffer
					m := v.(map[string]interface{})
					buf.WriteString(fmt.Sprintf("%s-", m["device_name"].(string)))
					buf.WriteString(fmt.Sprintf("%s-", m["virtual_name"].(string)))
					return hashcode.String(buf.String())
				},
			},

			"root_block_device": &schema.Schema{
				// TODO: This is a set because we don't support singleton
				//       sub-resources today. We'll enforce that the set only ever has
				//       length zero or one below. When TF gains support for
				//       sub-resources this can be converted.
				Type:     schema.TypeSet,
				Optional: true,
				Computed: true,
				Elem: &schema.Resource{
					// "You can only modify the volume size, volume type, and Delete on
					// Termination flag on the block device mapping entry for the root
					// device volume." - bit.ly/ec2bdmap
					Schema: map[string]*schema.Schema{
						"delete_on_termination": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Default:  true,
							ForceNew: true,
						},

						"iops": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"volume_size": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"volume_type": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},
					},
				},
				Set: func(v interface{}) int {
					// there can be only one root device; no need to hash anything
					return 0
				},
			},
		},
	}
}

func resourceAwsInstanceCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	instanceOpts, err := buildAwsInstanceOpts(d, meta)
	if err != nil {
		return err
	}

	// Build the creation struct
	runOpts := &ec2.RunInstancesInput{
		BlockDeviceMappings:   instanceOpts.BlockDeviceMappings,
		DisableAPITermination: instanceOpts.DisableAPITermination,
		EBSOptimized:          instanceOpts.EBSOptimized,
		IAMInstanceProfile:    instanceOpts.IAMInstanceProfile,
		ImageID:               instanceOpts.ImageID,
		InstanceType:          instanceOpts.InstanceType,
		KeyName:               instanceOpts.KeyName,
		MaxCount:              aws.Long(int64(1)),
		MinCount:              aws.Long(int64(1)),
		NetworkInterfaces:     instanceOpts.NetworkInterfaces,
		Placement:             instanceOpts.Placement,
		PrivateIPAddress:      instanceOpts.PrivateIPAddress,
		SecurityGroupIDs:      instanceOpts.SecurityGroupIDs,
		SecurityGroups:        instanceOpts.SecurityGroups,
		SubnetID:              instanceOpts.SubnetID,
		UserData:              instanceOpts.UserData64,
	}

	// Create the instance
	log.Printf("[DEBUG] Run configuration: %s", awsutil.StringValue(runOpts))

	var runResp *ec2.Reservation
	for i := 0; i < 5; i++ {
		runResp, err = conn.RunInstances(runOpts)
		if awsErr, ok := err.(awserr.Error); ok {
			// IAM profiles can take ~10 seconds to propagate in AWS:
			//  http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#launch-instance-with-role-console
			if awsErr.Code() == "InvalidParameterValue" && strings.Contains(awsErr.Message(), "Invalid IAM Instance Profile") {
				log.Printf("[DEBUG] Invalid IAM Instance Profile referenced, retrying...")
				time.Sleep(2 * time.Second)
				continue
			}
		}
		break
	}
	if err != nil {
		return fmt.Errorf("Error launching source instance: %s", err)
	}

	instance := runResp.Instances[0]
	log.Printf("[INFO] Instance ID: %s", *instance.InstanceID)

	// Store the resulting ID so we can look this up later
	d.SetId(*instance.InstanceID)

	// Wait for the instance to become running so we can get some attributes
	// that aren't available until later.
	log.Printf(
		"[DEBUG] Waiting for instance (%s) to become running",
		*instance.InstanceID)

	stateConf := &resource.StateChangeConf{
		Pending:    []string{"pending"},
		Target:     "running",
		Refresh:    InstanceStateRefreshFunc(conn, *instance.InstanceID),
		Timeout:    10 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	instanceRaw, err := stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for instance (%s) to become ready: %s",
			*instance.InstanceID, err)
	}

	instance = instanceRaw.(*ec2.Instance)

	// Initialize the connection info
	if instance.PublicIPAddress != nil {
		d.SetConnInfo(map[string]string{
			"type": "ssh",
			"host": *instance.PublicIPAddress,
		})
	} else if instance.PrivateIPAddress != nil {
		d.SetConnInfo(map[string]string{
			"type": "ssh",
			"host": *instance.PrivateIPAddress,
		})
	}

	// Set our attributes
	if err := resourceAwsInstanceRead(d, meta); err != nil {
		return err
	}

	// Update if we need to
	return resourceAwsInstanceUpdate(d, meta)
}

func resourceAwsInstanceRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	resp, err := conn.DescribeInstances(&ec2.DescribeInstancesInput{
		InstanceIDs: []*string{aws.String(d.Id())},
	})
	if err != nil {
		// If the instance was not found, return nil so that we can show
		// that the instance is gone.
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidInstanceID.NotFound" {
			d.SetId("")
			return nil
		}

		// Some other error, report it
		return err
	}

	// If nothing was found, then return no state
	if len(resp.Reservations) == 0 {
		d.SetId("")
		return nil
	}

	instance := resp.Reservations[0].Instances[0]

	// If the instance is terminated, then it is gone
	if *instance.State.Name == "terminated" {
		d.SetId("")
		return nil
	}

	if instance.Placement != nil {
		d.Set("availability_zone", instance.Placement.AvailabilityZone)
	}
	if instance.Placement.Tenancy != nil {
		d.Set("tenancy", instance.Placement.Tenancy)
	}

	d.Set("instance_type", instance.InstanceType)
	d.Set("key_name", instance.KeyName)
	d.Set("public_dns", instance.PublicDNSName)
	d.Set("public_ip", instance.PublicIPAddress)
	d.Set("private_dns", instance.PrivateDNSName)
	d.Set("private_ip", instance.PrivateIPAddress)
	if len(instance.NetworkInterfaces) > 0 {
		d.Set("subnet_id", instance.NetworkInterfaces[0].SubnetID)
	} else {
		d.Set("subnet_id", instance.SubnetID)
	}
	d.Set("ebs_optimized", instance.EBSOptimized)
	d.Set("tags", tagsToMap(instance.Tags))

	// Determine whether we're referring to security groups with
	// IDs or names. We use a heuristic to figure this out. By default,
	// we use IDs if we're in a VPC. However, if we previously had an
	// all-name list of security groups, we use names. Or, if we had any
	// IDs, we use IDs.
	useID := instance.SubnetID != nil && *instance.SubnetID != ""
	if v := d.Get("security_groups"); v != nil {
		match := useID
		sgs := v.(*schema.Set).List()
		if len(sgs) > 0 {
			match = false
			for _, v := range v.(*schema.Set).List() {
				if strings.HasPrefix(v.(string), "sg-") {
					match = true
					break
				}
			}
		}

		useID = match
	}

	// Build up the security groups
	sgs := make([]string, 0, len(instance.SecurityGroups))
	if useID {
		for _, sg := range instance.SecurityGroups {
			sgs = append(sgs, *sg.GroupID)
		}
		log.Printf("[DEBUG] Setting Security Group IDs: %#v", sgs)
		if err := d.Set("vpc_security_group_ids", sgs); err != nil {
			return err
		}
	} else {
		for _, sg := range instance.SecurityGroups {
			sgs = append(sgs, *sg.GroupName)
		}
		log.Printf("[DEBUG] Setting Security Group Names: %#v", sgs)
		if err := d.Set("security_groups", sgs); err != nil {
			return err
		}
	}

	if err := readBlockDevices(d, instance, conn); err != nil {
		return err
	}

	return nil
}

func resourceAwsInstanceUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	d.Partial(true)
	if err := setTags(conn, d); err != nil {
		return err
	} else {
		d.SetPartial("tags")
	}

	// SourceDestCheck can only be set on VPC instances
	if d.Get("subnet_id").(string) != "" {
		log.Printf("[INFO] Modifying instance %s", d.Id())
		_, err := conn.ModifyInstanceAttribute(&ec2.ModifyInstanceAttributeInput{
			InstanceID: aws.String(d.Id()),
			SourceDestCheck: &ec2.AttributeBooleanValue{
				Value: aws.Boolean(d.Get("source_dest_check").(bool)),
			},
		})
		if err != nil {
			return err
		}
	}

	if d.HasChange("vpc_security_group_ids") {
		var groups []*string
		if v := d.Get("vpc_security_group_ids").(*schema.Set); v.Len() > 0 {
			for _, v := range v.List() {
				groups = append(groups, aws.String(v.(string)))
			}
		}
		_, err := conn.ModifyInstanceAttribute(&ec2.ModifyInstanceAttributeInput{
			InstanceID: aws.String(d.Id()),
			Groups:     groups,
		})
		if err != nil {
			return err
		}
	}

	if d.HasChange("disable_api_termination") {
		_, err := conn.ModifyInstanceAttribute(&ec2.ModifyInstanceAttributeInput{
			InstanceID: aws.String(d.Id()),
			DisableAPITermination: &ec2.AttributeBooleanValue{
				Value: aws.Boolean(d.Get("disable_api_termination").(bool)),
			},
		})
		if err != nil {
			return err
		}
	}

	// TODO(mitchellh): wait for the attributes we modified to
	// persist the change...

	d.Partial(false)

	return resourceAwsInstanceRead(d, meta)
}

func resourceAwsInstanceDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	if err := awsTerminateInstance(conn, d.Id()); err != nil {
		return err
	}

	d.SetId("")
	return nil
}

// InstanceStateRefreshFunc returns a resource.StateRefreshFunc that is used to watch
// an EC2 instance.
func InstanceStateRefreshFunc(conn *ec2.EC2, instanceID string) resource.StateRefreshFunc {
	return func() (interface{}, string, error) {
		resp, err := conn.DescribeInstances(&ec2.DescribeInstancesInput{
			InstanceIDs: []*string{aws.String(instanceID)},
		})
		if err != nil {
			if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidInstanceID.NotFound" {
				// Set this to nil as if we didn't find anything.
				resp = nil
			} else {
				log.Printf("Error on InstanceStateRefresh: %s", err)
				return nil, "", err
			}
		}

		if resp == nil || len(resp.Reservations) == 0 || len(resp.Reservations[0].Instances) == 0 {
			// Sometimes AWS just has consistency issues and doesn't see
			// our instance yet. Return an empty state.
			return nil, "", nil
		}

		i := resp.Reservations[0].Instances[0]
		return i, *i.State.Name, nil
	}
}

func readBlockDevices(d *schema.ResourceData, instance *ec2.Instance, conn *ec2.EC2) error {
	ibds, err := readBlockDevicesFromInstance(instance, conn)
	if err != nil {
		return err
	}

	if err := d.Set("ebs_block_device", ibds["ebs"]); err != nil {
		return err
	}
	if ibds["root"] != nil {
		if err := d.Set("root_block_device", []interface{}{ibds["root"]}); err != nil {
			return err
		}
	}

	return nil
}

func readBlockDevicesFromInstance(instance *ec2.Instance, conn *ec2.EC2) (map[string]interface{}, error) {
	blockDevices := make(map[string]interface{})
	blockDevices["ebs"] = make([]map[string]interface{}, 0)
	blockDevices["root"] = nil

	instanceBlockDevices := make(map[string]*ec2.InstanceBlockDeviceMapping)
	for _, bd := range instance.BlockDeviceMappings {
		if bd.EBS != nil {
			instanceBlockDevices[*(bd.EBS.VolumeID)] = bd
		}
	}

	if len(instanceBlockDevices) == 0 {
		return nil, nil
	}

	volIDs := make([]*string, 0, len(instanceBlockDevices))
	for volID := range instanceBlockDevices {
		volIDs = append(volIDs, aws.String(volID))
	}

	// Need to call DescribeVolumes to get volume_size and volume_type for each
	// EBS block device
	volResp, err := conn.DescribeVolumes(&ec2.DescribeVolumesInput{
		VolumeIDs: volIDs,
	})
	if err != nil {
		return nil, err
	}

	for _, vol := range volResp.Volumes {
		instanceBd := instanceBlockDevices[*vol.VolumeID]
		bd := make(map[string]interface{})

		if instanceBd.EBS != nil && instanceBd.EBS.DeleteOnTermination != nil {
			bd["delete_on_termination"] = *instanceBd.EBS.DeleteOnTermination
		}
		if vol.Size != nil {
			bd["volume_size"] = *vol.Size
		}
		if vol.VolumeType != nil {
			bd["volume_type"] = *vol.VolumeType
		}
		if vol.IOPS != nil {
			bd["iops"] = *vol.IOPS
		}

		if blockDeviceIsRoot(instanceBd, instance) {
			blockDevices["root"] = bd
		} else {
			if instanceBd.DeviceName != nil {
				bd["device_name"] = *instanceBd.DeviceName
			}
			if vol.Encrypted != nil {
				bd["encrypted"] = *vol.Encrypted
			}
			if vol.SnapshotID != nil {
				bd["snapshot_id"] = *vol.SnapshotID
			}

			blockDevices["ebs"] = append(blockDevices["ebs"].([]map[string]interface{}), bd)
		}
	}

	return blockDevices, nil
}

func blockDeviceIsRoot(bd *ec2.InstanceBlockDeviceMapping, instance *ec2.Instance) bool {
	return (bd.DeviceName != nil &&
		instance.RootDeviceName != nil &&
		*bd.DeviceName == *instance.RootDeviceName)
}

func fetchRootDeviceName(ami string, conn *ec2.EC2) (*string, error) {
	if ami == "" {
		return nil, fmt.Errorf("Cannot fetch root device name for blank AMI ID.")
	}

	log.Printf("[DEBUG] Describing AMI %q to get root block device name", ami)
	res, err := conn.DescribeImages(&ec2.DescribeImagesInput{
		ImageIDs: []*string{aws.String(ami)},
	})
	if err != nil {
		return nil, err
	}

	// For a bad image, we just return nil so we don't block a refresh
	if len(res.Images) == 0 {
		return nil, nil
	}

	image := res.Images[0]
	rootDeviceName := image.RootDeviceName

	// Some AMIs have a RootDeviceName like "/dev/sda1" that does not appear as a
	// DeviceName in the BlockDeviceMapping list (which will instead have
	// something like "/dev/sda")
	//
	// While this seems like it breaks an invariant of AMIs, it ends up working
	// on the AWS side, and AMIs like this are common enough that we need to
	// special case it so Terraform does the right thing.
	//
	// Our heuristic is: if the RootDeviceName does not appear in the
	// BlockDeviceMapping, assume that the DeviceName of the first
	// BlockDeviceMapping entry serves as the root device.
	rootDeviceNameInMapping := false
	for _, bdm := range image.BlockDeviceMappings {
		if bdm.DeviceName == image.RootDeviceName {
			rootDeviceNameInMapping = true
		}
	}

	if !rootDeviceNameInMapping && len(image.BlockDeviceMappings) > 0 {
		rootDeviceName = image.BlockDeviceMappings[0].DeviceName
	}

	return rootDeviceName, nil
}

func readBlockDeviceMappingsFromConfig(
	d *schema.ResourceData, conn *ec2.EC2) ([]*ec2.BlockDeviceMapping, error) {
	blockDevices := make([]*ec2.BlockDeviceMapping, 0)

	if v, ok := d.GetOk("ebs_block_device"); ok {
		vL := v.(*schema.Set).List()
		for _, v := range vL {
			bd := v.(map[string]interface{})
			ebs := &ec2.EBSBlockDevice{
				DeleteOnTermination: aws.Boolean(bd["delete_on_termination"].(bool)),
			}

			if v, ok := bd["snapshot_id"].(string); ok && v != "" {
				ebs.SnapshotID = aws.String(v)
			}

			if v, ok := bd["encrypted"].(bool); ok && v {
				ebs.Encrypted = aws.Boolean(v)
			}

			if v, ok := bd["volume_size"].(int); ok && v != 0 {
				ebs.VolumeSize = aws.Long(int64(v))
			}

			if v, ok := bd["volume_type"].(string); ok && v != "" {
				ebs.VolumeType = aws.String(v)
			}

			if v, ok := bd["iops"].(int); ok && v > 0 {
				ebs.IOPS = aws.Long(int64(v))
			}

			blockDevices = append(blockDevices, &ec2.BlockDeviceMapping{
				DeviceName: aws.String(bd["device_name"].(string)),
				EBS:        ebs,
			})
		}
	}

	if v, ok := d.GetOk("ephemeral_block_device"); ok {
		vL := v.(*schema.Set).List()
		for _, v := range vL {
			bd := v.(map[string]interface{})
			blockDevices = append(blockDevices, &ec2.BlockDeviceMapping{
				DeviceName:  aws.String(bd["device_name"].(string)),
				VirtualName: aws.String(bd["virtual_name"].(string)),
			})
		}
	}

	if v, ok := d.GetOk("root_block_device"); ok {
		vL := v.(*schema.Set).List()
		if len(vL) > 1 {
			return nil, fmt.Errorf("Cannot specify more than one root_block_device.")
		}
		for _, v := range vL {
			bd := v.(map[string]interface{})
			ebs := &ec2.EBSBlockDevice{
				DeleteOnTermination: aws.Boolean(bd["delete_on_termination"].(bool)),
			}

			if v, ok := bd["volume_size"].(int); ok && v != 0 {
				ebs.VolumeSize = aws.Long(int64(v))
			}

			if v, ok := bd["volume_type"].(string); ok && v != "" {
				ebs.VolumeType = aws.String(v)
			}

			if v, ok := bd["iops"].(int); ok && v > 0 {
				ebs.IOPS = aws.Long(int64(v))
			}

			if dn, err := fetchRootDeviceName(d.Get("ami").(string), conn); err == nil {
				if dn == nil {
					return nil, fmt.Errorf(
						"Expected 1 AMI for ID: %s, got none",
						d.Get("ami").(string))
				}

				blockDevices = append(blockDevices, &ec2.BlockDeviceMapping{
					DeviceName: dn,
					EBS:        ebs,
				})
			} else {
				return nil, err
			}
		}
	}

	return blockDevices, nil
}

type awsInstanceOpts struct {
	BlockDeviceMappings   []*ec2.BlockDeviceMapping
	DisableAPITermination *bool
	EBSOptimized          *bool
	IAMInstanceProfile    *ec2.IAMInstanceProfileSpecification
	ImageID               *string
	InstanceType          *string
	KeyName               *string
	NetworkInterfaces     []*ec2.InstanceNetworkInterfaceSpecification
	Placement             *ec2.Placement
	PrivateIPAddress      *string
	SecurityGroupIDs      []*string
	SecurityGroups        []*string
	SpotPlacement         *ec2.SpotPlacement
	SubnetID              *string
	UserData64            *string
}

func buildAwsInstanceOpts(
	d *schema.ResourceData, meta interface{}) (*awsInstanceOpts, error) {
	conn := meta.(*AWSClient).ec2conn

	opts := &awsInstanceOpts{
		DisableAPITermination: aws.Boolean(d.Get("disable_api_termination").(bool)),
		EBSOptimized:          aws.Boolean(d.Get("ebs_optimized").(bool)),
		ImageID:               aws.String(d.Get("ami").(string)),
		InstanceType:          aws.String(d.Get("instance_type").(string)),
	}

	opts.IAMInstanceProfile = &ec2.IAMInstanceProfileSpecification{
		Name: aws.String(d.Get("iam_instance_profile").(string)),
	}

	opts.UserData64 = aws.String(
		base64.StdEncoding.EncodeToString([]byte(d.Get("user_data").(string))))

	// check for non-default Subnet, and cast it to a String
	subnet, hasSubnet := d.GetOk("subnet_id")
	subnetID := subnet.(string)

	// Placement is used for aws_instance; SpotPlacement is used for
	// aws_spot_instance_request. They represent the same data. :-|
	opts.Placement = &ec2.Placement{
		AvailabilityZone: aws.String(d.Get("availability_zone").(string)),
		GroupName:        aws.String(d.Get("placement_group").(string)),
	}

	opts.SpotPlacement = &ec2.SpotPlacement{
		AvailabilityZone: aws.String(d.Get("availability_zone").(string)),
		GroupName:        aws.String(d.Get("placement_group").(string)),
	}

	if v := d.Get("tenancy").(string); v != "" {
		opts.Placement.Tenancy = aws.String(v)
	}

	associatePublicIPAddress := d.Get("associate_public_ip_address").(bool)

	var groups []*string
	if v := d.Get("security_groups"); v != nil {
		// Security group names.
		// For a nondefault VPC, you must use security group IDs instead.
		// See http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RunInstances.html
		sgs := v.(*schema.Set).List()
		if len(sgs) > 0 && hasSubnet {
			log.Printf("[WARN] Deprecated. Attempting to use 'security_groups' within a VPC instance. Use 'vpc_security_group_ids' instead.")
		}
		for _, v := range sgs {
			str := v.(string)
			groups = append(groups, aws.String(str))
		}
	}

	if hasSubnet && associatePublicIPAddress {
		// If we have a non-default VPC / Subnet specified, we can flag
		// AssociatePublicIpAddress to get a Public IP assigned. By default these are not provided.
		// You cannot specify both SubnetId and the NetworkInterface.0.* parameters though, otherwise
		// you get: Network interfaces and an instance-level subnet ID may not be specified on the same request
		// You also need to attach Security Groups to the NetworkInterface instead of the instance,
		// to avoid: Network interfaces and an instance-level security groups may not be specified on
		// the same request
		ni := &ec2.InstanceNetworkInterfaceSpecification{
			AssociatePublicIPAddress: aws.Boolean(associatePublicIPAddress),
			DeviceIndex:              aws.Long(int64(0)),
			SubnetID:                 aws.String(subnetID),
			Groups:                   groups,
		}

		if v, ok := d.GetOk("private_ip"); ok {
			ni.PrivateIPAddress = aws.String(v.(string))
		}

		if v := d.Get("vpc_security_group_ids").(*schema.Set); v.Len() > 0 {
			for _, v := range v.List() {
				ni.Groups = append(ni.Groups, aws.String(v.(string)))
			}
		}

		opts.NetworkInterfaces = []*ec2.InstanceNetworkInterfaceSpecification{ni}
	} else {
		if subnetID != "" {
			opts.SubnetID = aws.String(subnetID)
		}

		if v, ok := d.GetOk("private_ip"); ok {
			opts.PrivateIPAddress = aws.String(v.(string))
		}
		if opts.SubnetID != nil &&
			*opts.SubnetID != "" {
			opts.SecurityGroupIDs = groups
		} else {
			opts.SecurityGroups = groups
		}

		if v := d.Get("vpc_security_group_ids").(*schema.Set); v.Len() > 0 {
			for _, v := range v.List() {
				opts.SecurityGroupIDs = append(opts.SecurityGroupIDs, aws.String(v.(string)))
			}
		}
	}

	if v, ok := d.GetOk("key_name"); ok {
		opts.KeyName = aws.String(v.(string))
	}

	blockDevices, err := readBlockDeviceMappingsFromConfig(d, conn)
	if err != nil {
		return nil, err
	}
	if len(blockDevices) > 0 {
		opts.BlockDeviceMappings = blockDevices
	}

	return opts, nil
}

func awsTerminateInstance(conn *ec2.EC2, id string) error {
	log.Printf("[INFO] Terminating instance: %s", id)
	req := &ec2.TerminateInstancesInput{
		InstanceIDs: []*string{aws.String(id)},
	}
	if _, err := conn.TerminateInstances(req); err != nil {
		return fmt.Errorf("Error terminating instance: %s", err)
	}

	log.Printf("[DEBUG] Waiting for instance (%s) to become terminated", id)

	stateConf := &resource.StateChangeConf{
		Pending:    []string{"pending", "running", "shutting-down", "stopped", "stopping"},
		Target:     "terminated",
		Refresh:    InstanceStateRefreshFunc(conn, id),
		Timeout:    10 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	_, err := stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for instance (%s) to terminate: %s", id, err)
	}

	return nil
}
