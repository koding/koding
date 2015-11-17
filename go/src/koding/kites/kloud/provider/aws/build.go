package awsprovider

import (
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/userdata"

	kiteprotocol "github.com/koding/kite/protocol"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/nu7hatch/gouuid"
	"golang.org/x/net/context"
)

const (
	DefaultUbuntuImage = "ami-d05e75b8"

	KodingGroupName = "Koding-Kloud-SG"
	KodingGroupDesc = "Koding VMs group"
)

type BuildData struct {
	// EC2Data is passed directly to aws-sdk-go to create the final instance.
	EC2Data   *ec2.RunInstancesInput
	ImageData *ImageData
	KiteId    string
}

type ImageData struct {
	blockDeviceMapping *ec2.BlockDeviceMapping
	imageID            string
}

func (m *Machine) Build(ctx context.Context) (err error) {
	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not available")
	}

	// the user might send us a snapshot id
	var args struct {
		Reason string
	}

	err = req.Args.One().Unmarshal(&args)
	if err != nil {
		return err
	}

	reason := "Machine is building."
	if args.Reason != "" {
		reason += "Custom reason: " + args.Reason
	}

	if err := m.UpdateState(reason, machinestate.Building); err != nil {
		return err
	}

	latestState := m.State()
	defer func() {
		// run any availabile cleanupFunction
		m.runCleanupFunctions()

		// if there is any error mark it as NotInitialized
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	if m.Meta.InstanceName == "" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	// if there is already a machine just check it again
	if m.Meta.InstanceId == "" {
		m.push("Generating and fetching build data", 10, machinestate.Building)

		m.Log.Debug("Generating and fetching build data")
		buildData, err := m.buildData(ctx)
		if err != nil {
			return err
		}

		m.Meta.SourceAmi = buildData.ImageData.imageID
		m.QueryString = kiteprotocol.Kite{ID: buildData.KiteId}.String()

		m.push("Initiating build process", 30, machinestate.Building)
		m.Log.Debug("Initiating creating process of instance")

		m.Meta.InstanceId, err = m.Session.AWSClient.Build(buildData.EC2Data)
		if err != nil {
			return err
		}

		if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				m.Id,
				bson.M{"$set": bson.M{
					"meta.instanceId": m.Meta.InstanceId,
					"meta.source_ami": m.Meta.SourceAmi,
					"meta.region":     m.Meta.Region,
					"queryString":     m.QueryString,
				}},
			)
		}); err != nil {
			return err
		}
	} else {
		m.Log.Debug("Continue build process with data, instanceId: '%s' and queryString: '%s'",
			m.Meta.InstanceId, m.QueryString)
	}

	m.push("Checking build process", 40, machinestate.Building)
	m.Log.Debug("Checking build process of instanceId '%s'", m.Meta.InstanceId)

	instance, err := m.Session.AWSClient.CheckBuild(ctx, m.Meta.InstanceId, 50, 70)
	if amazon.IsNotFound(err) || err == amazon.ErrInstanceTerminated {
		if err := m.MarkAsNotInitialized(); err != nil {
			return err
		}

		return errors.New("instance is not available anymore")
	}

	if err != nil {
		return err
	}

	m.Meta.InstanceType = aws.StringValue(instance.InstanceType)
	m.Meta.SourceAmi = aws.StringValue(instance.ImageId)
	m.IpAddress = aws.StringValue(instance.PublicIpAddress)

	m.push("Adding and setting up domains and tags", 70, machinestate.Building)
	m.addDomainAndTags()

	m.push(fmt.Sprintf("Checking klient connection '%s'", m.IpAddress), 80, machinestate.Building)
	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	resultInfo := fmt.Sprintf("username: [%s], instanceId: [%s], ipAdress: [%s], kiteQuery: [%s]",
		m.Username, m.Meta.InstanceId, m.IpAddress, m.QueryString)

	m.Log.Info("========== BUILD results ========== %s", resultInfo)

	reason = "Machine is build successfully."
	if args.Reason != "" {
		reason += "Custom reason: " + args.Reason
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         m.IpAddress,
				"queryString":       m.QueryString,
				"meta.instanceType": m.Meta.InstanceType,
				"meta.instanceName": m.Meta.InstanceName,
				"meta.instanceId":   m.Meta.InstanceId,
				"meta.source_ami":   m.Meta.SourceAmi,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     reason,
			}},
		)
	})
}

func (m *Machine) imageData() (*ImageData, error) {
	if m.Meta.StorageSize == 0 {
		return nil, errors.New("storage size is zero")
	}

	m.Log.Debug("Fetching image which is tagged with '%s'", m.Meta.SourceAmi)

	imageID := m.Meta.SourceAmi
	if imageID == "" {
		m.Log.Critical("Source AMI is not set, using default Ubuntu AMI: %s", DefaultUbuntuImage)
		imageID = DefaultUbuntuImage
	}

	image, err := m.Session.AWSClient.ImageByID(imageID)
	if err != nil {
		return nil, err
	}

	if len(image.BlockDeviceMappings) == 0 {
		return nil, &amazon.NotFoundError{
			Resource: "BlockDeviceMapping",
			Err:      fmt.Errorf("no block device mapping found within image=%q", imageID),
		}
	}
	if len(image.BlockDeviceMappings) > 1 {
		m.Log.Warning("more than one block device mapping for image=%q: %+v", imageID, image.BlockDeviceMappings)
	}

	device := image.BlockDeviceMappings[0]

	// The lowest commong storage size for public Images is 8. To have a
	// smaller storage size (like we do have for Koding, one must create new
	// image). We assume that nodody did this :)
	if m.Meta.StorageSize < 8 {
		m.Meta.StorageSize = 8
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	blockDeviceMapping := &ec2.BlockDeviceMapping{
		DeviceName:  device.DeviceName,
		VirtualName: device.VirtualName,
		Ebs: &ec2.EbsBlockDevice{
			VolumeType:          aws.String("standard"), // Use magnetic storage because it is cheaper
			VolumeSize:          aws.Int64(int64(m.Meta.StorageSize)),
			DeleteOnTermination: aws.Bool(true),
		},
	}

	imageID = aws.StringValue(image.ImageId)

	m.Log.Debug("Using image Id: %q and block device settings %+v", imageID, blockDeviceMapping)

	return &ImageData{
		imageID:            imageID,
		blockDeviceMapping: blockDeviceMapping,
	}, nil
}

// buildData returns all necessary data that is needed to build a machine.
func (m *Machine) buildData(ctx context.Context) (*BuildData, error) {
	imageData, err := m.imageData()
	if err != nil {
		return nil, err
	}

	if m.Session.AWSClient.Builder.InstanceType == "" {
		return nil, errors.New("instance type is empty")
	}

	kiteUUID, err := uuid.NewV4()
	if err != nil {
		return nil, err
	}

	kiteId := kiteUUID.String()

	m.Log.Debug("Creating user data")

	sshKeys := make([]string, len(m.User.SshKeys))
	for i, sshKey := range m.User.SshKeys {
		sshKeys[i] = sshKey.Key
	}

	cloudInitConfig := &userdata.CloudInitConfig{
		Username:    m.Username,
		Groups:      []string{"sudo"},
		UserSSHKeys: sshKeys,
		Hostname:    m.Username, // no typo here. hostname = username
		KiteId:      kiteId,
	}

	userdata, err := m.Session.Userdata.Create(cloudInitConfig)
	if err != nil {
		return nil, err
	}

	keys, ok := publickeys.FromContext(ctx)
	if !ok {
		return nil, errors.New("public keys are not available")
	}

	subnets, err := m.Session.AWSClient.Subnets()
	if err != nil {
		return nil, err
	}

	// find a subnet with available IPs
	//
	// TODO(rjeczalik): in other place we're picking the subnet with min(AvailableIpAddressCount),
	// do the same here?
	var subnetID, vpcID string
	for _, subnet := range subnets {
		if aws.Int64Value(subnet.AvailableIpAddressCount) == 0 {
			continue
		}
		subnetID = aws.StringValue(subnet.SubnetId)
		vpcID = aws.StringValue(subnet.VpcId)
		// TODO(rjeczalik): stop after first subnet found?
	}
	if subnetID == "" {
		return nil, errors.New("did not found a subnet with available IPs")
	}

	var groupID string

	switch group, err := m.Session.AWSClient.SecurityGroupByName(KodingGroupName); {
	case err == nil:
		groupID = aws.StringValue(group.GroupId)
	case amazon.IsNotFound(err):
		groupID, err = m.Session.AWSClient.Client.CreateSecurityGroup(KodingGroupName, vpcID, KodingGroupDesc)
		if err != nil {
			return nil, err
		}
		// TODO(rjeczalik): make CreateSecurityGroup blocking with WaitUntil*
		//
		// use retry mechanism
		// We loop and retry this a few times because sometimes the security
		// group isn't available immediately because AWS resources are eventaully
		// consistent.
		for i := 0; i < 5; i++ {
			err = m.Session.AWSClient.Client.AuthorizeSecurityGroup(groupID, amazon.PermAllPorts)
			if err == nil {
				break
			}

			m.Log.Error("Error authorizing. Will sleep and retry. %s", err)
			time.Sleep((time.Duration(i) * time.Second) + 1)
		}
		if err != nil {
			return nil, err
		}
	default:
		return nil, err
	}

	m.Session.AWSClient.Builder.KeyPair = keys.KeyName
	m.Session.AWSClient.Builder.PrivateKey = keys.PrivateKey
	m.Session.AWSClient.Builder.PublicKey = keys.PublicKey

	keyName, err := m.Session.AWSClient.DeployKey()
	if err != nil {
		return nil, err
	}

	ec2Data := &ec2.RunInstancesInput{
		ImageId:      aws.String(imageData.imageID),
		MinCount:     aws.Int64(1),
		MaxCount:     aws.Int64(1),
		KeyName:      aws.String(keyName),
		InstanceType: aws.String(m.Session.AWSClient.Builder.InstanceType),
		NetworkInterfaces: []*ec2.InstanceNetworkInterfaceSpecification{{
			DeviceIndex: aws.Int64(0),
			SubnetId:    aws.String(subnetID),
			Groups:      []*string{aws.String(groupID)},
			AssociatePublicIpAddress: aws.Bool(true),
		}},
		BlockDeviceMappings: []*ec2.BlockDeviceMapping{imageData.blockDeviceMapping},
		UserData:            aws.String(base64.StdEncoding.EncodeToString(userdata)),
	}

	return &BuildData{
		EC2Data:   ec2Data,
		ImageData: imageData,
		KiteId:    kiteId,
	}, nil
}

func (m *Machine) addDomainAndTags() {
	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	m.Log.Debug("Adding and setting up domain and tags")
	if m.Meta.InstanceName == "terminated-instance" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		m.Log.Debug("Instance name is an artifact (terminated), changing to %s", m.Meta.InstanceName)
	}

	m.push("Updating/Creating domain", 70, machinestate.Building)
	m.Log.Debug("Updating/Creating domain %s", m.IpAddress)

	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	m.push("Updating domain aliases", 72, machinestate.Building)
	domains, err := m.Session.DNSStorage.GetByMachine(m.Id.Hex())
	if err != nil {
		m.Log.Error("fetching domains for setting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
	}

	tags := map[string]string{
		"Name":             m.Meta.InstanceName,
		"koding-user":      m.Username,
		"koding-env":       m.Session.Kite.Config.Environment,
		"koding-machineId": m.Id.Hex(),
		"koding-domain":    m.Domain,
	}

	m.Log.Debug("Adding user tags %v", tags)
	if err := m.Session.AWSClient.AddTags(m.Meta.InstanceId, tags); err != nil {
		m.Log.Error("Adding tags failed: %v", err)
	}
}
