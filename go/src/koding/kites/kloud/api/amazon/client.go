package amazon

import (
	"encoding/base64"
	"errors"
	"fmt"
	"koding/kites/kloud/awscompat"
	"net/url"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/logging"
)

// TODO(rjeczalik): make all Create* methods blocking with aws.WaitUntil*

// TODO(rjeczalik): support paginated replies for Describe* calls

// Client wraps *ec.EC2 with an API that hides Input/Output structs
// while dealing with EC2 service API.
type Client struct {
	EC2    *ec2.EC2 // underlying client
	Region string   // region name
	Zones  []string // zone list
	Log    logging.Logger
}

// NewClient creates new *ec2.EC2 wrapper.
//
// If log is non-nil, it's used for debug logging EC2 service.
func NewClient(auth client.ConfigProvider, region string, log logging.Logger) (*Client, error) {
	cfg := aws.NewConfig().WithRegion(region)
	if log != nil {
		cfg = cfg.WithLogger(NewLogger(log.Debug))
	}
	svc := ec2.New(auth, cfg)
	svc.Client.Retryer = awscompat.Retry
	zones, err := svc.DescribeAvailabilityZones(nil)
	if err != nil {
		return nil, awsError(err)
	}
	c := &Client{
		EC2:    svc,
		Region: region,
		Zones:  make([]string, len(zones.AvailabilityZones)),
		Log:    log,
	}
	for i, zone := range zones.AvailabilityZones {
		c.Zones[i] = aws.StringValue(zone.ZoneName)
	}
	return c, nil
}

// AddressesByIP is a wrapper for (*ec2.EC2).DescribeAddresses.
//
// If call succeeds but no addresses were found, it returns non-nil
// *NotFoundError error.
func (c *Client) AddressesByIP(publicIP string) ([]*ec2.Address, error) {
	params := &ec2.DescribeAddressesInput{
		PublicIps: []*string{aws.String(publicIP)},
	}
	resp, err := c.EC2.DescribeAddresses(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Addresses) == 0 {
		return nil, newNotFoundError("Address", fmt.Errorf("no addresses found with ip=%q", publicIP))
	}
	return resp.Addresses, nil
}

// ReleaseAddresss is a wrapper for (*ec2.EC2).ReleaseAddress.
func (c *Client) ReleaseAddress(allocID string) error {
	params := &ec2.ReleaseAddressInput{
		AllocationId: aws.String(allocID),
	}
	_, err := c.EC2.ReleaseAddress(params)
	return awsError(err)
}

// AllocateAddress is a wrapper for (*ec2.EC2).AllocateAddress.
//
// The domain type can be either classic or vpc.
func (c *Client) AllocateAddress(domainType string) (allocID, publicIP string, err error) {
	params := &ec2.AllocateAddressInput{
		Domain: aws.String(domainType),
	}
	resp, err := c.EC2.AllocateAddress(params)
	if err != nil {
		return "", "", awsError(err)
	}
	return aws.StringValue(resp.AllocationId), aws.StringValue(resp.PublicIp), nil
}

// AssociateAddress is a wrapper for (*ec2.EC2).AssociateAddres.
func (c *Client) AssociateAddress(instanceID, allocID string) error {
	params := &ec2.AssociateAddressInput{
		InstanceId:   aws.String(instanceID),
		AllocationId: aws.String(allocID),
	}
	_, err := c.EC2.AssociateAddress(params)
	return awsError(err)
}

// Images is a wrapper for (*ec2.EC2).DescribeImages.
//
// If call succeeds but no images were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Images() ([]*ec2.Image, error) {
	resp, err := c.EC2.DescribeImages(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Images) == 0 {
		return nil, newNotFoundError("Image", errors.New("no images found"))
	}
	return resp.Images, nil
}

// ImageByID is a wrapper for (*ec2.EC2).DescribeImages with image-id filter.
func (c *Client) ImageByID(id string) (*ec2.Image, error) {
	return c.imageBy("image-id", id)
}

// ImageByName is a wrapper for (*ec2.EC2).DescribeImages with name filter.
func (c *Client) ImageByName(name string) (*ec2.Image, error) {
	return c.imageBy("name", name)
}

// ImageByTag is a wrapper for (*ec2.EC2).DescribeImages with tag:Name filter.
func (c *Client) ImageByTag(tag string) (*ec2.Image, error) {
	return c.imageBy("tag:Name", tag)
}

func (c *Client) imageBy(key, value string) (*ec2.Image, error) {
	params := &ec2.DescribeImagesInput{
		Filters: []*ec2.Filter{{
			Name:   aws.String(key),
			Values: []*string{aws.String(value)},
		}},
	}
	resp, err := c.EC2.DescribeImages(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Images) == 0 {
		return nil, newNotFoundError("Image", fmt.Errorf("no image found with key=%v, value=%v", key, value))
	}
	if len(resp.Images) > 1 {
		c.Log.Warning("more than one image found with key=%q, value=%q: %+v", key, value, resp.Images)
	}
	return resp.Images[0], nil
}

// RegisterImage is a wrapper for (*ec2.EC2).RegisterImage.
func (c *Client) RegisterImage(params *ec2.RegisterImageInput) (imageID string, err error) {
	resp, err := c.EC2.RegisterImage(params)
	if err != nil {
		return "", awsError(err)
	}
	return aws.StringValue(resp.ImageId), nil
}

// DeregisterImage is a wrapper for (*ec2.EC2).DeregisterImage.
func (c *Client) DeregisterImage(imageID string) error {
	params := &ec2.DeregisterImageInput{
		ImageId: aws.String(imageID),
	}
	_, err := c.EC2.DeregisterImage(params)
	return awsError(err)
}

// Snapshots is a wrapper for (*ec2.EC2).DescribeSnapshots.
//
// If call succeeds but no snapshots were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Snapshots() ([]*ec2.Snapshot, error) {
	resp, err := c.EC2.DescribeSnapshots(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Snapshots) == 0 {
		return nil, newNotFoundError("Snapshot", errors.New("no snapshots found"))
	}
	return resp.Snapshots, nil
}

// SnapshotByID is a wrapper for (*ec.EC2).DescribeSnapshots with id filter.
func (c *Client) SnapshotByID(id string) (*ec2.Snapshot, error) {
	params := &ec2.DescribeSnapshotsInput{
		SnapshotIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.DescribeSnapshots(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Snapshots) == 0 {
		return nil, newNotFoundError("Snapshot", fmt.Errorf("no snapshot found with id=%s", id))
	}
	if len(resp.Snapshots) > 1 {
		c.Log.Warning("more than one snapshot found  with id=%s: %+v", id, resp.Snapshots)
	}
	return resp.Snapshots[0], nil
}

// CreateSnapshot is a wrapper for (*ec2.EC2).CreateSnapshot.
func (c *Client) CreateSnapshot(volumeID, desc string) (*ec2.Snapshot, error) {
	params := &ec2.CreateSnapshotInput{
		VolumeId:    aws.String(volumeID),
		Description: aws.String(desc),
	}
	snapshot, err := c.EC2.CreateSnapshot(params)
	return snapshot, awsError(err)
}

// DeleteSnapshot is a wrapper for (*ec2.EC2).DeleteSnapshot.
func (c *Client) DeleteSnapshot(id string) error {
	params := &ec2.DeleteSnapshotInput{
		SnapshotId: aws.String(id),
	}
	_, err := c.EC2.DeleteSnapshot(params)
	return awsError(err)
}

// VPCs is a wrapper for (*ec2.EC2).DescribeVpcs.
//
// If call succeeds but no VPCs were found, it returns non-nil
// *NotFoundError error.
func (c *Client) VPCs() ([]*ec2.Vpc, error) {
	resp, err := c.EC2.DescribeVpcs(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Vpcs) == 0 {
		return nil, newNotFoundError("VPC", errors.New("no VPCs found"))
	}
	return resp.Vpcs, nil
}

// Subnets is a wrapper for (*ec2.EC2).DescribeSubnets.
//
// If call succeeds but no subnets were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Subnets() ([]*ec2.Subnet, error) {
	resp, err := c.EC2.DescribeSubnets(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Subnets) == 0 {
		return nil, newNotFoundError("Subnet", errors.New("no subnets found"))
	}
	return resp.Subnets, nil
}

// SubnetsByTag is a wrapper for (*ec2.EC2).DescribeSubnets with tag-value filter.
//
// If call succeeds but no subnets were found, it returns non-nil
// *NotFoundError error.
func (c *Client) SubnetsByTag(value string) ([]*ec2.Subnet, error) {
	params := &ec2.DescribeSubnetsInput{
		Filters: []*ec2.Filter{{
			Name:   aws.String("tag-value"),
			Values: []*string{aws.String(value)},
		}},
	}
	resp, err := c.EC2.DescribeSubnets(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Subnets) == 0 {
		return nil, newNotFoundError("Subnet", fmt.Errorf("no subnets found with tag=%q", value))
	}
	return resp.Subnets, nil
}

// SecurityGroupByID is a wrapper for (*ec2.EC2).DescribeSecurityGroups with id filter.
func (c *Client) SecurityGroupByID(id string) (*ec2.SecurityGroup, error) {
	params := &ec2.DescribeSecurityGroupsInput{
		GroupIds: []*string{aws.String(id)},
	}
	return c.securityGroupBy(params, id)
}

// SecurityGroupByName is a wrapper for (*ec2.EC2).DescribeSecurityGroups with name filter.
func (c *Client) SecurityGroupByName(name string) (*ec2.SecurityGroup, error) {
	params := &ec2.DescribeSecurityGroupsInput{
		GroupNames: []*string{aws.String(name)},
	}
	return c.securityGroupBy(params, name)
}

// SecurityGroupByFilters is a wrapper for (*ec2.EC2).DescribeSecurityGroups
// with user-defined filters.
//
// If the value of a certain filter is an empty string, the filter is ignored.
func (c *Client) SecurityGroupByFilters(filters url.Values) (*ec2.SecurityGroup, error) {
	params := &ec2.DescribeSecurityGroupsInput{
		Filters: NewFilters(filters),
	}
	return c.securityGroupBy(params, filters)
}

// SecurityGroupFromVPC is a wrapper for (*ec2.EC2).DescribeSecurityGroups
// with vpc-id and tag-key filters.
//
// If the value of either argument is empty, the filter is ignored.
func (c *Client) SecurityGroupFromVPC(vpcID, tag string) (*ec2.SecurityGroup, error) {
	filters := url.Values{
		"vpc-id":  {vpcID},
		"tag-key": {tag},
	}
	return c.SecurityGroupByFilters(filters)
}

func (c *Client) securityGroupBy(params *ec2.DescribeSecurityGroupsInput, key interface{}) (*ec2.SecurityGroup, error) {
	resp, err := c.EC2.DescribeSecurityGroups(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.SecurityGroups) == 0 {
		return nil, newNotFoundError("SecurityGroup", fmt.Errorf("no security group found with key=%v", key))
	}
	if len(resp.SecurityGroups) > 1 {
		c.Log.Warning("more than one security group found with key=%v: %+v", key, resp.SecurityGroups)
	}
	return resp.SecurityGroups[0], nil
}

// CreateSecurityGroup is a wrapper for (*ec2.EC2).CreateSecurityGroup.
func (c *Client) CreateSecurityGroup(name, vpcID, desc string) (groupID string, err error) {
	params := &ec2.CreateSecurityGroupInput{
		GroupName:   aws.String(name),
		VpcId:       aws.String(vpcID),
		Description: aws.String(desc),
	}
	resp, err := c.EC2.CreateSecurityGroup(params)
	if err != nil {
		return "", awsError(err)
	}
	return aws.StringValue(resp.GroupId), nil
}

// AuthorizeSecurityGroup is a wrapper for (*ec2.EC2).AuthorizeSecurityGroup.
func (c *Client) AuthorizeSecurityGroup(id string, perm []*ec2.IpPermission) error {
	params := &ec2.AuthorizeSecurityGroupIngressInput{
		GroupId:       aws.String(id),
		IpPermissions: perm,
	}
	_, err := c.EC2.AuthorizeSecurityGroupIngress(params)
	return awsError(err)
}

// AddTag is a wrapper for (*ec2.EC2).CreateTags.
func (c *Client) AddTag(resourceID, key, value string) error {
	return c.AddTags(resourceID, map[string]string{key: value})
}

// AddTags is a wrapper for (*ec2.EC2).CreateTags.
func (c *Client) AddTags(resourceID string, tags map[string]string) error {
	params := &ec2.CreateTagsInput{
		Resources: []*string{aws.String(resourceID)},
		Tags:      NewTags(tags),
	}
	_, err := c.EC2.CreateTags(params)
	return awsError(err)
}

// InstaceByID is a wrapper for (*ec2.EC2).DescribeInstances with id filter.
func (c *Client) InstanceByID(id string) (*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.DescribeInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	instances := collectInstances(resp.Reservations)
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%s", id))
	}
	if len(instances) > 1 {
		c.Log.Warning("more than one instance found with id=%s: %+v", id, instances)
	}
	return instances[0], nil
}

// InstancesByFilters is a wrapper for (*ec2.EC2).DescribeInstances with
// user-defined filters.
//
// If the value of a certain filter is an empty string, the filter is ignored.
// If call succeeds but no instances were found, it returns non-nil
// *NotFoundError error.
func (c *Client) InstancesByFilters(filters url.Values) ([]*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		Filters: NewFilters(filters),
	}
	resp, err := c.EC2.DescribeInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	instances := collectInstances(resp.Reservations)
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instances found with filters=%v", filters))
	}
	return instances, nil
}

func collectInstances(reservations []*ec2.Reservation) (instances []*ec2.Instance) {
	for _, r := range reservations {
		for _, i := range r.Instances {
			instances = append(instances, i)
		}
	}
	return instances
}

// StartInstance is a wrapper for (*ec2.EC2).StartInstances.
func (c *Client) StartInstance(id string) (*ec2.InstanceStateChange, error) {
	params := &ec2.StartInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.StartInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.StartingInstances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	}
	if len(resp.StartingInstances) > 1 {
		c.Log.Warning("more than one instance started with id=%q: %+v", id, resp.StartingInstances)
	}
	return resp.StartingInstances[0], nil
}

// StopInstance is a wrapper for (*ec2.EC2).StopInstances.
func (c *Client) StopInstance(id string) (*ec2.InstanceStateChange, error) {
	params := &ec2.StopInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.StopInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.StoppingInstances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	}
	if len(resp.StoppingInstances) > 1 {
		c.Log.Warning("more than one instance stopped with id=%q: %+v", id, resp.StoppingInstances)
	}
	return resp.StoppingInstances[0], nil
}

// RebootInstance is a wrapper for (*ec2.EC2).RebootInstances.
func (c *Client) RebootInstance(id string) error {
	params := &ec2.RebootInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	_, err := c.EC2.RebootInstances(params)
	return awsError(err)
}

// TerminateInstance is a wrapper for (*ec2.EC2).TerminateInstances.
func (c *Client) TerminateInstance(id string) (*ec2.InstanceStateChange, error) {
	params := &ec2.TerminateInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.TerminateInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.TerminatingInstances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	}
	if len(resp.TerminatingInstances) > 1 {
		c.Log.Warning("more than one instance terminated with id=%q: %+v", id, resp.TerminatingInstances)
	}
	return resp.TerminatingInstances[0], nil
}

// KeyPairByName is a wrapper for (*ec2.EC2).DescribeKeyPairs with name filter.
func (c *Client) KeyPairByName(name string) (*ec2.KeyPairInfo, error) {
	params := &ec2.DescribeKeyPairsInput{
		KeyNames: []*string{aws.String(name)},
	}
	resp, err := c.EC2.DescribeKeyPairs(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.KeyPairs) == 0 {
		return nil, newNotFoundError("KeyPair", fmt.Errorf("no key pair found with name=%q", name))
	}
	if len(resp.KeyPairs) > 1 {
		c.Log.Warning("more than one key pair found with name=%q: %+v", name, resp.KeyPairs)
	}
	return resp.KeyPairs[0], nil
}

// DeleteKeyPair is a wrapper for (*ec2.EC2).DeleteKeyPair.
func (c *Client) DeleteKeyPair(name string) error {
	params := &ec2.DeleteKeyPairInput{
		KeyName: aws.String(name),
	}
	_, err := c.EC2.DeleteKeyPair(params)
	return awsError(err)
}

// ImportKeyPair is a wrapper for (*ec2.EC2).ImportKeyPair.
func (c *Client) ImportKeyPair(name string, publicKey []byte) (fingerprint string, err error) {
	params := &ec2.ImportKeyPairInput{
		KeyName:           aws.String(name),
		PublicKeyMaterial: []byte(base64.StdEncoding.EncodeToString(publicKey)),
	}
	resp, err := c.EC2.ImportKeyPair(params)
	if err != nil {
		return "", awsError(err)
	}
	return aws.StringValue(resp.KeyFingerprint), nil
}

// Volume is a wrapper for (*ec2.EC2).DescribeVolumes with id filter.
func (c *Client) VolumeByID(id string) (*ec2.Volume, error) {
	params := &ec2.DescribeVolumesInput{
		VolumeIds: []*string{aws.String(id)},
	}
	resp, err := c.EC2.DescribeVolumes(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Volumes) == 0 {
		return nil, newNotFoundError("Volume", fmt.Errorf("no volume found with id=%q", id))
	}
	if len(resp.Volumes) > 1 {
		c.Log.Warning("more than one volume found with id=%q: %+v", id, resp.Volumes)
	}
	return resp.Volumes[0], nil
}

// CreateVolume is a wrapper for (*ec2.EC2).Volume.
func (c *Client) CreateVolume(snapshotID, zone, typ string, size int64) (*ec2.Volume, error) {
	params := &ec2.CreateVolumeInput{
		AvailabilityZone: aws.String(zone),
		Size:             aws.Int64(size),
		SnapshotId:       aws.String(snapshotID),
		VolumeType:       aws.String(typ),
	}
	vol, err := c.EC2.CreateVolume(params)
	if err != nil {
		return nil, awsError(err)
	}
	return vol, nil
}

// DeleteVolume is a wrapper for (*ec.EC2).DeleteVolume.
func (c *Client) DeleteVolume(volID string) error {
	params := &ec2.DeleteVolumeInput{
		VolumeId: aws.String(volID),
	}
	_, err := c.EC2.DeleteVolume(params)
	return awsError(err)
}

// AttachVolume is a wrapper for (*ec2.EC2).Volume.
func (c *Client) AttachVolume(volumeID, instanceID, devicePath string) error {
	params := &ec2.AttachVolumeInput{
		VolumeId:   aws.String(volumeID),
		InstanceId: aws.String(instanceID),
		Device:     aws.String(devicePath),
	}
	_, err := c.EC2.AttachVolume(params)
	return awsError(err)
}

// Volume is a wrapper for (*ec2.EC2).Volume.
func (c *Client) DetachVolume(id string) error {
	params := &ec2.DetachVolumeInput{
		VolumeId: aws.String(id),
	}
	_, err := c.EC2.DetachVolume(params)
	return awsError(err)
}

// RunInstances is a wrapper for (*ec2.EC2).RunInstances.
func (c *Client) RunInstances(params *ec2.RunInstancesInput) (*ec2.Instance, error) {
	resp, err := c.EC2.RunInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance ran with params=%v", params))
	}
	if len(resp.Instances) > 1 {
		c.Log.Warning("more than one instance ran with params=%v: %+v", params, resp.Instances)
	}
	return resp.Instances[0], nil
}

// ModifyInstance is a wrapper for (*ec2.EC2).ModiftInstanceAttribute.
func (c *Client) ModifyInstance(params *ec2.ModifyInstanceAttributeInput) error {
	_, err := c.EC2.ModifyInstanceAttribute(params)
	return awsError(err)
}
