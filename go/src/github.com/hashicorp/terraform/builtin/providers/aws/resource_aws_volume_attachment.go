package aws

import (
	"bytes"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsVolumeAttachment() *schema.Resource {
	return &schema.Resource{
		Create: resourceAwsVolumeAttachmentCreate,
		Read:   resourceAwsVolumeAttachmentRead,
		Delete: resourceAwsVolumeAttachmentDelete,

		Schema: map[string]*schema.Schema{
			"device_name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"instance_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"volume_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"force_detach": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Computed: true,
			},
		},
	}
}

func resourceAwsVolumeAttachmentCreate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn
	name := d.Get("device_name").(string)
	iID := d.Get("instance_id").(string)
	vID := d.Get("volume_id").(string)

	opts := &ec2.AttachVolumeInput{
		Device:     aws.String(name),
		InstanceID: aws.String(iID),
		VolumeID:   aws.String(vID),
	}

	log.Printf("[DEBUG] Attaching Volume (%s) to Instance (%s)", vID, iID)
	_, err := conn.AttachVolume(opts)
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			return fmt.Errorf("[WARN] Error attaching volume (%s) to instance (%s), message: \"%s\", code: \"%s\"",
				vID, iID, awsErr.Message(), awsErr.Code())
		}
		return err
	}

	stateConf := &resource.StateChangeConf{
		Pending:    []string{"attaching"},
		Target:     "attached",
		Refresh:    volumeAttachmentStateRefreshFunc(conn, vID, iID),
		Timeout:    5 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	_, err = stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for Volume (%s) to attach to Instance: %s, error: %s",
			vID, iID, err)
	}

	d.SetId(volumeAttachmentID(name, vID, iID))
	return resourceAwsVolumeAttachmentRead(d, meta)
}

func volumeAttachmentStateRefreshFunc(conn *ec2.EC2, volumeID, instanceID string) resource.StateRefreshFunc {
	return func() (interface{}, string, error) {

		request := &ec2.DescribeVolumesInput{
			VolumeIDs: []*string{aws.String(volumeID)},
			Filters: []*ec2.Filter{
				&ec2.Filter{
					Name:   aws.String("attachment.instance-id"),
					Values: []*string{aws.String(instanceID)},
				},
			},
		}

		resp, err := conn.DescribeVolumes(request)
		if err != nil {
			if awsErr, ok := err.(awserr.Error); ok {
				return nil, "failed", fmt.Errorf("code: %s, message: %s", awsErr.Code(), awsErr.Message())
			}
			return nil, "failed", err
		}

		if len(resp.Volumes) > 0 {
			v := resp.Volumes[0]
			for _, a := range v.Attachments {
				if a.InstanceID != nil && *a.InstanceID == instanceID {
					return a, *a.State, nil
				}
			}
		}
		// assume detached if volume count is 0
		return 42, "detached", nil
	}
}
func resourceAwsVolumeAttachmentRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	request := &ec2.DescribeVolumesInput{
		VolumeIDs: []*string{aws.String(d.Get("volume_id").(string))},
		Filters: []*ec2.Filter{
			&ec2.Filter{
				Name:   aws.String("attachment.instance-id"),
				Values: []*string{aws.String(d.Get("instance_id").(string))},
			},
		},
	}

	_, err := conn.DescribeVolumes(request)
	if err != nil {
		if ec2err, ok := err.(awserr.Error); ok && ec2err.Code() == "InvalidVolume.NotFound" {
			d.SetId("")
			return nil
		}
		return fmt.Errorf("Error reading EC2 volume %s for instance: %s: %#v", d.Get("volume_id").(string), d.Get("instance_id").(string), err)
	}
	return nil
}

func resourceAwsVolumeAttachmentDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	vID := d.Get("volume_id").(string)
	iID := d.Get("instance_id").(string)

	opts := &ec2.DetachVolumeInput{
		Device:     aws.String(d.Get("device_name").(string)),
		InstanceID: aws.String(iID),
		VolumeID:   aws.String(vID),
		Force:      aws.Boolean(d.Get("force_detach").(bool)),
	}

	_, err := conn.DetachVolume(opts)
	stateConf := &resource.StateChangeConf{
		Pending:    []string{"detaching"},
		Target:     "detached",
		Refresh:    volumeAttachmentStateRefreshFunc(conn, vID, iID),
		Timeout:    5 * time.Minute,
		Delay:      10 * time.Second,
		MinTimeout: 3 * time.Second,
	}

	log.Printf("[DEBUG] Detaching Volume (%s) from Instance (%s)", vID, iID)
	_, err = stateConf.WaitForState()
	if err != nil {
		return fmt.Errorf(
			"Error waiting for Volume (%s) to detach from Instance: %s",
			vID, iID)
	}
	d.SetId("")
	return nil
}

func volumeAttachmentID(name, volumeID, instanceID string) string {
	var buf bytes.Buffer
	buf.WriteString(fmt.Sprintf("%s-", name))
	buf.WriteString(fmt.Sprintf("%s-", instanceID))
	buf.WriteString(fmt.Sprintf("%s-", volumeID))

	return fmt.Sprintf("vai-%d", hashcode.String(buf.String()))
}
