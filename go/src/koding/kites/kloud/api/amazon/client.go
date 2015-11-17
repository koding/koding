package amazon

import (
	"errors"
	"fmt"
	"koding/kites/kloud/awscompat"
	"log"
	"net/url"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/service/ec2"
)

// TODO(rjeczalik): make all Create* methods blocking with aws.WaitUntil*

// Client wraps *ec.EC2 with an API that hides Input/Output structs
// while dealing with EC2 service API.
//
// TODO(rjeczalik): add `Log logging.Logger`
type Client struct {
	EC2    *ec2.EC2 // underlying client
	Region string   // region name
	Zones  []string // zone list
}

func newClient(cfg client.ConfigProvider, region string) (*Client, error) {
	svc := ec2.New(cfg, aws.NewConfig().WithRegion(region))
	svc.Client.Retryer = awscompat.Retry
	zones, err := svc.DescribeAvailabilityZones(&ec2.DescribeAvailabilityZonesInput{})
	if err != nil {
		return nil, awsError(err)
	}
	c := &Client{
		EC2:    svc,
		Region: region,
		Zones:  make([]string, len(zones.AvailabilityZones)),
	}
	for i, zone := range zones.AvailabilityZones {
		c.Zones[i] = aws.StringValue(zone.ZoneName)
	}
	return c, nil
}

// AddressesByIP is a wrapper for (*ec2.EC2).DescribeAddresses.
//
// If call succeeds but no addresses were found, it returns no-nil
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
// If call succeeds but no images were found, it returns no-nil
// *NotFoundError error.
func (c *Client) Images() ([]*ec2.Image, error) {
	params := &ec2.DescribeImagesInput{}
	resp, err := c.EC2.DescribeImages(params)
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
	switch n := len(resp.Images); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Image", fmt.Errorf("no image found with key=%v, value=%v", key, value))
	default:
		log.Printf("multiec2: more than one image found with key=%q, value=%q: %d", key, value, n)
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
// If call succeeds but no snapshots were found, it returns no-nil
// *NotFoundError error.
func (c *Client) Snapshots() ([]*ec2.Snapshot, error) {
	params := &ec2.DescribeSnapshotsInput{}
	resp, err := c.EC2.DescribeSnapshots(params)
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
	switch n := len(resp.Snapshots); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Snapshot", fmt.Errorf("no snapshot found with id=%s", id))
	default:
		log.Printf("multiec2: more than one snapshot found  with id=%s: %d", id, n)
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
// If call succeeds but no VPCs were found, it returns no-nil
// *NotFoundError error.
func (c *Client) VPCs() ([]*ec2.Vpc, error) {
	params := &ec2.DescribeVpcsInput{}
	resp, err := c.EC2.DescribeVpcs(params)
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
// If call succeeds but no subnets were found, it returns no-nil
// *NotFoundError error.
func (c *Client) Subnets() ([]*ec2.Subnet, error) {
	params := &ec2.DescribeSubnetsInput{}
	resp, err := c.EC2.DescribeSubnets(params)
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
// If call succeeds but no subnets were found, it returns no-nil
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
	switch n := len(resp.SecurityGroups); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("SecurityGroup", fmt.Errorf("no security group found with key=%v", key))
	default:
		log.Printf("multiec2: more than one security group found with key=%v: %d", key, n)
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
func (c *Client) AddTag(instanceID, key, value string) error {
	return c.AddTags(instanceID, map[string]string{key: value})
}

// AddTags is a wrapper for (*ec2.EC2).CreateTags.
func (c *Client) AddTags(instanceID string, tags map[string]string) error {
	params := &ec2.CreateTagsInput{
		Resources: []*string{aws.String(instanceID)},
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
	switch n := len(resp.Reservations); {
	case n == 1 && len(resp.Reservations[0].Instances) == 1: // ok
	case n == 0 || len(resp.Reservations[0].Instances) == 0:
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%d", id))
	default:
		log.Printf("multiec2: more than one instance found with id=%d", id)
	}
	return resp.Reservations[0].Instances[0], nil
}

// InstancesByFilters is a wrapper for (*ec2.EC2).DescribeInstances with
// user-defined filters.
//
// If the value of a certain filter is an empty string, the filter is ignored.
// If call succeeds but no instances were found, it returns no-nil
// *NotFoundError error.
func (c *Client) InstancesByFilters(filters url.Values) ([]*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		Filters: NewFilters(filters),
	}
	resp, err := c.EC2.DescribeInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	var instances []*ec2.Instance
	for _, r := range resp.Reservations {
		for _, i := range r.Instances {
			instances = append(instances, i)
		}
	}
	if len(instances) == 0 {
		return nil, fmt.Errorf("no instances found with filters=%v", filters)
	}
	return instances, nil
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
	switch n := len(resp.StartingInstances); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	default:
		log.Printf("multiec2: more than one instance started with id=%q: %d", id, n)
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
	switch n := len(resp.StoppingInstances); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	default:
		log.Printf("multiec2: more than one instance stopped with id=%q: %d", id, n)
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
	switch n := len(resp.TerminatingInstances); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%q", id))
	default:
		log.Printf("multiec2: more than one instance terminated with id=%q: %d", id, n)
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
	switch n := len(resp.KeyPairs); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("KeyPair", fmt.Errorf("no key pair found with name=%q", name))
	default:
		log.Printf("multiec2: more than one key pair found with name=%q", name)
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
		PublicKeyMaterial: publicKey,
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
	switch n := len(resp.Volumes); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Volume", fmt.Errorf("no volume found with id=%q", id))
	default:
		log.Printf("multiec2: more than one volume found with id=%q", id)
	}
	return resp.Volumes[0], nil
}

// CreateVolume is a wrapper for (*ec2.EC2).Volume.
func (c *Client) CreateVolume(snapshotID, zone, typ string, size int64) (*ec2.Volume, error) {
	params := &ec2.CreateVolumeInput{
		AvailabilityZone: aws.String(typ),
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
	switch n := len(resp.Instances); n {
	case 1: // ok
	case 0:
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance ran with params=%v", params))
	default:
		log.Printf("multiec2: more than one instance ran with params=%v", params)
	}
	return resp.Instances[0], nil
}

// ModifyInstance is a wrapper for (*ec2.EC2).ModiftInstanceAttribute.
func (c *Client) ModifyInstance(params *ec2.ModifyInstanceAttributeInput) error {
	_, err := c.EC2.ModifyInstanceAttribute(params)
	return awsError(err)
}
