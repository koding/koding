package amazon

import (
	"encoding/base64"
	"errors"
	"fmt"
	"net/url"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/private/waiter"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/logging"
)

// TODO(rjeczalik): make all Create* methods blocking with aws.WaitUntil*

// Client wraps *ec.EC2 with an API that hides Input/Output structs
// while dealing with EC2 service API.
type Client struct {
	EC2        *ec2.EC2 // underlying client
	Region     string   // region name
	Zones      []string // zone list
	Log        logging.Logger
	MaxResults int64
}

// NewClient creates new *ec2.EC2 wrapper.
//
// If log is non-nil, it's used for debug logging EC2 service.
// If calling NewClient succeeds, it means the client is authenticated
// and is ready for issuing requests.
func NewClient(opts *ClientOptions) (*Client, error) {
	cfg := NewSession(opts)
	svc := ec2.New(cfg)
	c := &Client{
		EC2:        svc,
		Region:     aws.StringValue(cfg.Config.Region),
		Log:        opts.Log,
		MaxResults: opts.MaxResults,
	}

	if !opts.NoZones {
		zones, err := c.SubnetAvailabilityZones()
		if err != nil {
			return nil, awsError(err)
		}

		c.Zones = zones
	}

	return c, nil
}

// Addresses is a wrapper for (*ec2.EC2).DescribeAddresses.
//
// If call succeeds but no addresses were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Addresses() ([]*ec2.Address, error) {
	// DescribeAddresses' reply is not paginated.
	resp, err := c.EC2.DescribeAddresses(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Addresses) == 0 {
		return nil, newNotFoundError("Address", errors.New("no addresses found"))
	}
	return resp.Addresses, nil
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

// AssociateAddress is a wrapper for (*ec2.EC2).AssociateAddress.
func (c *Client) AssociateAddress(instanceID, allocID string) error {
	params := &ec2.AssociateAddressInput{
		InstanceId:   aws.String(instanceID),
		AllocationId: aws.String(allocID),
	}
	_, err := c.EC2.AssociateAddress(params)
	return awsError(err)
}

// DisassociateAddress is a wrapper for (*ec2.EC2).DisassociateAddress.
func (c *Client) DisassociateAddress(assocID string) error {
	params := &ec2.DisassociateAddressInput{
		AssociationId: aws.String(assocID),
	}
	_, err := c.EC2.DisassociateAddress(params)
	return awsError(err)
}

// Images is a wrapper for (*ec2.EC2).DescribeImages.
//
// If call succeeds but no images were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Images() ([]*ec2.Image, error) {
	// DescribeImages' reply is not paginated.
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
func (c *Client) ImageByID(id string) (*Image, error) {
	return c.imageBy("image-id", id)
}

// ImageByName is a wrapper for (*ec2.EC2).DescribeImages with name filter.
func (c *Client) ImageByName(name string) (*Image, error) {
	return c.imageBy("name", name)
}

// ImageByTag is a wrapper for (*ec2.EC2).DescribeImages with tag:Name filter.
func (c *Client) ImageByTag(tag string) (*Image, error) {
	return c.imageBy("tag:Name", tag)
}

func (c *Client) imageBy(key, value string) (*Image, error) {
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
	return &Image{
		Image: resp.Images[0],
	}, nil
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

// Snapshots is a wrapper for (*ec2.EC2).DescribeSnapshotsPages.
//
// If call succeeds but no snapshots were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Snapshots() ([]*ec2.Snapshot, error) {
	var snapshots []*ec2.Snapshot
	var params ec2.DescribeSnapshotsInput
	if c.MaxResults != 0 {
		params.MaxResults = aws.Int64(c.MaxResults)
	}
	var page int
	err := c.EC2.DescribeSnapshotsPages(&params, func(resp *ec2.DescribeSnapshotsOutput, _ bool) bool {
		page++
		c.Log.Debug("received %d snapshots (page=%d)", len(resp.Snapshots), page)
		snapshots = append(snapshots, resp.Snapshots...)
		return true
	})
	if err != nil {
		return nil, awsError(err)
	}
	if len(snapshots) == 0 {
		return nil, newNotFoundError("Snapshot", errors.New("no snapshots found"))
	}
	return snapshots, nil
}

// SnapshotByID is a wrapper for (*ec.EC2).DescribeSnapshots with id filter.
func (c *Client) SnapshotByID(id string) (*ec2.Snapshot, error) {
	// DescribeSnapshots' reply is not paginated when SnapshotIds is set.
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
	// DescribeVpcs' reply is not paginated.
	resp, err := c.EC2.DescribeVpcs(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.Vpcs) == 0 {
		return nil, newNotFoundError("VPC", errors.New("no VPCs found"))
	}
	return resp.Vpcs, nil
}

var errUnknownZones = errors.New("unable to guess availability zones")

// SubnetAvailabilityZones gives all availability zones that can be used
// for creating a subnet for the account.
func (c *Client) SubnetAvailabilityZones() ([]string, error) {
	zones, err := c.guessAvailabilityZones()
	if err == nil {
		return zones, nil
	}

	resp, err := c.EC2.DescribeAvailabilityZones(nil)
	if err != nil {
		return nil, awsError(err)
	}

	zones = make([]string, len(resp.AvailabilityZones))

	for i, zone := range resp.AvailabilityZones {
		zones[i] = aws.StringValue(zone.ZoneName)
	}

	return zones, nil
}

func (c *Client) guessAvailabilityZones() ([]string, error) {
	const errMsg = "Subnets can currently only be created in the following availability zones:"

	params := &ec2.CreateSubnetInput{
		AvailabilityZone: aws.String("invalid"),
		VpcId:            aws.String("invalid"),
		CidrBlock:        aws.String("10.0.0.0/24"),
	}

	_, err := c.EC2.CreateSubnet(params)
	if err == nil {
		return nil, errUnknownZones
	}

	msg := err.Error()

	i := strings.Index(msg, errMsg)
	if i == -1 {
		return nil, errUnknownZones
	}

	zones := strings.Split(strings.Trim(msg[i+len(errMsg):], " ."), ", ")

	if len(zones) == 0 || zones[0] == "" {
		return nil, errUnknownZones
	}

	return zones, nil
}

// Subnets is a wrapper for (*ec2.EC2).DescribeSubnets.
//
// If call succeeds but no subnets were found, it returns non-nil
// *NotFoundError error.
func (c *Client) Subnets() ([]*ec2.Subnet, error) {
	// DescribeSubnets' reply is not paginated.
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

// TagsByFilters is a wrapper for (*ec.EC2).DescribeTagsPages.
//
// If call succeeds but no subnets were found, it returns non-nil
// *NotFoundError error.
func (c *Client) TagsByFilters(filters url.Values) (map[string]string, error) {
	var tags []*ec2.TagDescription
	var params = &ec2.DescribeTagsInput{
		Filters: NewFilters(filters),
	}
	// Update MaxResults param if no filtering options were set.
	if params.Filters == nil && c.MaxResults != 0 {
		params.MaxResults = aws.Int64(c.MaxResults)
	}
	var page int
	err := c.EC2.DescribeTagsPages(params, func(resp *ec2.DescribeTagsOutput, _ bool) bool {
		page++
		c.Log.Debug("received %d tags (page=%d)", len(resp.Tags), page)
		tags = append(tags, resp.Tags...)
		return true
	})
	if err != nil {
		return nil, awsError(err)
	}
	if len(tags) == 0 {
		return nil, newNotFoundError("Tag", errors.New("no tags found"))
	}
	m := make(map[string]string, len(tags))
	for _, tag := range tags {
		key := aws.StringValue(tag.Key)
		val := aws.StringValue(tag.Value)
		if _, ok := m[key]; ok {
			c.Log.Error("duplicated tag key=%q, value=%q", key, val)
		}
		m[key] = val
	}
	return m, nil
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

// InstanceStatusByID is a wrapper for (*ec2.EC2).DescribeInstanceStatusPages.
//
// If call succeeds but no instances were found, it returns non-nil
// *NotFoundError error.
func (c *Client) InstanceStatuses() ([]*ec2.InstanceStatus, error) {
	return c.InstanceStatusesByFilter(nil)
}

// InstanceStatusByID is a wrapper for (*ec2.EC2).DescribeInstanceStatusPages
// with id filter.
func (c *Client) InstanceStatusByID(id string) (*ec2.InstanceStatus, error) {
	params := &ec2.DescribeInstanceStatusInput{
		InstanceIds: []*string{aws.String(id)},
	}
	statuses, err := c.instanceStatuses(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(statuses) > 1 {
		c.Log.Warning("more than one instance status found with id=%s: %+v", id, statuses)
	}
	if len(statuses) == 0 {
		return nil, newNotFoundError("InstanceStatus", fmt.Errorf("no instance status found with id=%q", id))
	}

	return statuses[0], nil
}

// InstanceStatusByFilter is a wrapper for (*ec2.EC2).DescribeInstanceStatusPages
// with user-defined filters.
//
// If filters are nil statuses for all running are returned.
// If the value of a certain filter is an empty string, the filter is ignored.
// If call succeeds but no instances were found, it returns non-nil
// *NotFoundError error.
func (c *Client) InstanceStatusesByFilter(filters url.Values) ([]*ec2.InstanceStatus, error) {
	params := &ec2.DescribeInstanceStatusInput{
		Filters: NewFilters(filters),
	}
	statuses, err := c.instanceStatuses(params)
	if err != nil {
		return nil, awsError(err)
	}
	return statuses, nil
}

func (c *Client) instanceStatuses(params *ec2.DescribeInstanceStatusInput) (statuses []*ec2.InstanceStatus, err error) {
	if params == nil {
		params = &ec2.DescribeInstanceStatusInput{}
	}
	// Update MaxResults param if no filtering options were set.
	if params.Filters == nil && params.InstanceIds == nil && c.MaxResults != 0 {
		params.MaxResults = aws.Int64(c.MaxResults)
	}
	var page int
	return statuses, c.EC2.DescribeInstanceStatusPages(params, func(resp *ec2.DescribeInstanceStatusOutput, _ bool) bool {
		page++
		c.Log.Debug("received %d instance statuses (page=%d)", len(resp.InstanceStatuses), page)
		statuses = append(statuses, resp.InstanceStatuses...)
		return true
	})
}

// Instances is a wraper for (*ec2.EC2).DescribeInstancesPages.
func (c *Client) Instances() ([]*ec2.Instance, error) {
	instances, err := c.instances(nil)
	if err != nil {
		return nil, awsError(err)
	}
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", errors.New("no instance found"))
	}
	return instances, nil
}

// InstaceByID is a wrapper for (*ec2.EC2).DescribeInstancesPages with id filter.
func (c *Client) InstanceByID(id string) (*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		InstanceIds: []*string{aws.String(id)},
	}
	instances, err := c.instances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with id=%s", id))
	}
	if len(instances) > 1 {
		c.Log.Warning("more than one instance found with id=%s: %+v", id, instances)
	}
	return instances[0], nil
}

// InstancesByIDs is a wrapper for (*ec2.EC2).DescribeInstancesPages with ids filter.
func (c *Client) InstancesByIDs(ids ...string) ([]*ec2.Instance, error) {
	if len(ids) == 0 {
		return nil, errors.New("passed empty ID list")
	}
	params := &ec2.DescribeInstancesInput{
		InstanceIds: make([]*string, len(ids)),
	}
	for i, id := range ids {
		params.InstanceIds[i] = aws.String(id)
	}
	instances, err := c.instances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance found with ids=%s", ids))
	}
	if len(instances) != len(ids) {
		c.Log.Warning("requested to stop %d instances; stopped %d", len(ids), len(instances))
	}
	return instances, nil
}

// InstancesByFilters is a wrapper for (*ec2.EC2).DescribeInstancesPages  with
// user-defined filters.
//
// If the value of a certain filter is an empty string, the filter is ignored.
// If call succeeds but no instances were found, it returns non-nil
// *NotFoundError error.
func (c *Client) InstancesByFilters(filters url.Values) ([]*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		Filters: NewFilters(filters),
	}
	instances, err := c.instances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(instances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instances found with filters=%v", filters))
	}
	return instances, nil
}

func (c *Client) instances(params *ec2.DescribeInstancesInput) (instances []*ec2.Instance, err error) {
	if params == nil {
		params = &ec2.DescribeInstancesInput{}
	}
	// Update MaxResults param if no filtering options were set.
	if params.Filters == nil && params.InstanceIds == nil && c.MaxResults != 0 {
		params.MaxResults = aws.Int64(c.MaxResults)
	}
	var page int
	return instances, c.EC2.DescribeInstancesPages(params, func(resp *ec2.DescribeInstancesOutput, _ bool) bool {
		respInstances := c.collectInstances(resp.Reservations)
		page++
		c.Log.Debug("received %d instances (page=%d)", len(respInstances), page)
		instances = append(instances, respInstances...)
		return true
	})
}

func (c *Client) collectInstances(reservations []*ec2.Reservation) (instances []*ec2.Instance) {
	for _, r := range reservations {
		for _, instance := range r.Instances {
			if instance == nil {
				// Don't collect nil instances - if none were collected, it means
				// we received empty response (e.g. http://git.io/v02mS), and
				// we will fail with *NotFoundError outside here.
				c.Log.Debug("received nil instance: %+v", reservations)
				continue
			}
			instances = append(instances, instance)
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
//
// If call succeeds but no instance were stopped, it returns non-nil
// *NotFoundError error.
func (c *Client) StopInstance(id string) (*ec2.InstanceStateChange, error) {
	stopped, err := c.StopInstances(id)
	if err != nil {
		return nil, awsError(err)
	}
	return stopped[0], nil
}

// StopInstances is a wrapper for (*ec2.EC2).StopInstances.
//
// If call succeeds but no instances were stopped, it returns non-nil
// *NotFoundError error.
func (c *Client) StopInstances(ids ...string) ([]*ec2.InstanceStateChange, error) {
	if len(ids) == 0 {
		return nil, errors.New("no instances to stop")
	}
	params := &ec2.StopInstancesInput{
		InstanceIds: make([]*string, len(ids)),
	}
	for i := range params.InstanceIds {
		params.InstanceIds[i] = aws.String(ids[i])
	}
	resp, err := c.EC2.StopInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.StoppingInstances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance stopped with ids=%v", ids))
	}
	if len(resp.StoppingInstances) != len(ids) {
		c.Log.Warning("requested to stop %d instances; stopped %d: %+v",
			len(ids), len(resp.StoppingInstances), resp.StoppingInstances)
	}
	return resp.StoppingInstances, nil
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
//
// If call succeeds but no instance were terminated, it returns non-nil
// *NotFoundError error.
func (c *Client) TerminateInstance(id string) (*ec2.InstanceStateChange, error) {
	terminated, err := c.TerminateInstances(id)
	if err != nil {
		return nil, awsError(err)
	}
	return terminated[0], nil
}

// TerminateInstances is a wrapper for (*ec2.EC2).TerminateInstances.
//
// If call succeeds but no instances were terminated, it returns non-nil
// *NotFoundError error.
func (c *Client) TerminateInstances(ids ...string) ([]*ec2.InstanceStateChange, error) {
	if len(ids) == 0 {
		return nil, errors.New("no instances to terminate")
	}
	params := &ec2.TerminateInstancesInput{
		InstanceIds: make([]*string, len(ids)),
	}
	for i := range params.InstanceIds {
		params.InstanceIds[i] = aws.String(ids[i])
	}
	resp, err := c.EC2.TerminateInstances(params)
	if err != nil {
		return nil, awsError(err)
	}
	if len(resp.TerminatingInstances) == 0 {
		return nil, newNotFoundError("Instance", fmt.Errorf("no instance terminated with ids=%v", ids))
	}
	if len(resp.TerminatingInstances) != len(ids) {
		c.Log.Warning("requested to terminate %d instances; terminated %d: %+v",
			len(ids), len(resp.TerminatingInstances), resp.TerminatingInstances)
	}
	return resp.TerminatingInstances, nil
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

// Volumes is a wrapper for (*ec2.EC2).DescribeVolumesPages.
func (c *Client) Volumes() ([]*ec2.Volume, error) {
	var volumes []*ec2.Volume
	var params ec2.DescribeVolumesInput
	if c.MaxResults != 0 {
		params.MaxResults = aws.Int64(c.MaxResults)
	}
	var page int
	err := c.EC2.DescribeVolumesPages(&params, func(resp *ec2.DescribeVolumesOutput, _ bool) bool {
		page++
		c.Log.Debug("received %d volumes (page=%d)", len(resp.Volumes), page)
		volumes = append(volumes, resp.Volumes...)
		return true
	})
	if err != nil {
		return nil, awsError(err)
	}
	if len(volumes) == 0 {
		return nil, newNotFoundError("Volume", errors.New("no volume found"))
	}
	return volumes, nil
}

// Volume is a wrapper for (*ec2.EC2).DescribeVolumes with id filter.
func (c *Client) VolumeByID(id string) (*ec2.Volume, error) {
	params := &ec2.DescribeVolumesInput{
		VolumeIds: []*string{aws.String(id)},
	}
	// DescribeVolumes' reply is not paginated when VolumeIds is set.
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

// CreateImage is a wrapper for (*ec2.EC2).CreateImage.
func (c *Client) CreateImage(instanceID, name string) (imageID string, err error) {
	params := &ec2.CreateImageInput{
		InstanceId: aws.String(instanceID),
		Name:       aws.String(name),
	}

	resp, err := c.EC2.CreateImage(params)
	if err != nil {
		return "", awsError(err)
	}

	return aws.StringValue(resp.ImageId), nil
}

// Image is a wrapper for ec2.Image.
type Image struct {
	*ec2.Image
}

// Snapshot gives the ID and size of the snapshot that image uses.
//
// NOTE(rjeczalik): The API was built for provider/aws migration of koding
// instances, which had only a single EBS.
func (i *Image) Snapshot() (string, int64, error) {
	for _, dev := range i.BlockDeviceMappings {
		if dev.Ebs == nil {
			continue
		}

		return aws.StringValue(dev.Ebs.SnapshotId), aws.Int64Value(dev.Ebs.VolumeSize), nil
	}

	return "", 0, fmt.Errorf("no snapshots found for %s image", i.ID())
}

// ID gives the image id.
func (i *Image) ID() string {
	return aws.StringValue(i.ImageId)
}

// WaitImage blocks until an imgage given by the imageID becomes
// available.
func (c *Client) WaitImage(imageID string) error {
	w := waiter.Waiter{
		Client: c.EC2,
		Input: &ec2.DescribeImagesInput{
			ImageIds: []*string{aws.String(imageID)},
		},
		Config: waiter.Config{
			Operation:   "DescribeImages",
			Delay:       15,
			MaxAttempts: 120,
			Acceptors: []waiter.WaitAcceptor{
				{
					State:    "success",
					Matcher:  "pathAll",
					Argument: "Images[].State",
					Expected: "available",
				},
				{
					State:    "failure",
					Matcher:  "pathAny",
					Argument: "Images[].State",
					Expected: "failed",
				},
			},
		},
	}

	return awsError(w.Wait())
}

// AllowCopyImage modifies the image attributes to allow access
// by a user given by the accountID.
//
// It also modifies its snapshot's permissions to allow the access.
func (c *Client) AllowCopyImage(image *Image, accountID string) error {
	snapshotID, _, err := image.Snapshot()
	if err != nil {
		return err
	}

	imgParams := &ec2.ModifyImageAttributeInput{
		ImageId: image.ImageId,
		LaunchPermission: &ec2.LaunchPermissionModifications{
			Add: []*ec2.LaunchPermission{{
				UserId: aws.String(accountID),
			}},
		},
	}

	_, err = c.EC2.ModifyImageAttribute(imgParams)
	if err != nil {
		return awsError(err)
	}

	snapParams := &ec2.ModifySnapshotAttributeInput{
		SnapshotId:    aws.String(snapshotID),
		Attribute:     aws.String("createVolumePermission"),
		OperationType: aws.String("add"),
		UserIds:       []*string{aws.String(accountID)},
	}

	_, err = c.EC2.ModifySnapshotAttribute(snapParams)
	return awsError(err)
}

// CopyImage imports the given source image, which may belong to different
// user.
func (c *Client) CopyImage(srcImageID, srcRegion, newName string) (newImageID string, err error) {
	params := &ec2.CopyImageInput{
		SourceImageId: aws.String(srcImageID),
		SourceRegion:  aws.String(srcRegion),
		Name:          aws.String(newName),
	}

	resp, err := c.EC2.CopyImage(params)
	if err != nil {
		return "", awsError(err)
	}

	return aws.StringValue(resp.ImageId), nil
}
