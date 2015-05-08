package awsprovider

import (
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

	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
	"golang.org/x/net/context"
)

var DefaultUbuntuImage = "ami-d05e75b8"

type BuildData struct {
	// This is passed directly to goamz to create the final instance
	EC2Data   *ec2.RunInstances
	ImageData *ImageData
	KiteId    string
}

type ImageData struct {
	blockDeviceMapping ec2.BlockDeviceMapping
	imageId            string
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

		m.Meta.SourceAmi = buildData.ImageData.imageId
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
	if err == amazon.ErrInstanceTerminated || err == amazon.ErrNoInstances {
		if err := m.markAsNotInitialized(); err != nil {
			return err
		}

		return errors.New("instance is not available anymore")
	}

	if err != nil {
		return err
	}

	m.Meta.InstanceType = instance.InstanceType
	m.Meta.SourceAmi = instance.ImageId
	m.IpAddress = instance.PublicIpAddress

	m.push("Adding and setting up domains and tags", 70, machinestate.Building)
	m.addDomainAndTags()

	m.push(fmt.Sprintf("Checking klient connection '%s'", m.IpAddress), 80, machinestate.Building)
	if !m.isKlientReady() {
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

	imageId := DefaultUbuntuImage
	if m.Meta.SourceAmi != "" {
		m.Log.Critical("Source AMI is not set, using default Ubuntu AMI: %s", DefaultUbuntuImage)
		imageId = m.Meta.SourceAmi
	}

	image, err := m.Session.AWSClient.Image(imageId)
	if err != nil {
		return nil, err
	}

	device := image.BlockDevices[0]

	// The lowest commong storage size for public Images is 8. To have a
	// smaller storage size (like we do have for Koding, one must create new
	// image). We assume that nodody did this :)
	if m.Meta.StorageSize < 8 {
		m.Meta.StorageSize = 8
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	blockDeviceMapping := ec2.BlockDeviceMapping{
		DeviceName:          device.DeviceName,
		VirtualName:         device.VirtualName,
		VolumeType:          "standard", // Use magnetic storage because it is cheaper
		VolumeSize:          int64(m.Meta.StorageSize),
		DeleteOnTermination: true,
		Encrypted:           false,
	}

	m.Log.Debug("Using image Id: %s and block device settings %v", image.Id, blockDeviceMapping)

	return &ImageData{
		imageId:            image.Id,
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

	subnets, err := m.Session.AWSClient.ListSubnets()
	if err != nil {
		return nil, err
	}

	if len(subnets.Subnets) == 0 {
		return nil, errors.New("no subnets are available")
	}

	var subnetId string
	var vpcId string
	for _, subnet := range subnets.Subnets {
		if subnet.AvailableIpAddressCount == 0 {
			continue
		}

		subnetId = subnet.SubnetId
		vpcId = subnet.VpcId
	}

	if subnetId == "" {
		return nil, errors.New("subnetId is empty")
	}

	var groupName = "Koding-Kloud-SG"
	var group ec2.SecurityGroup

	group, err = m.Session.AWSClient.SecurityGroup(groupName)
	if err != nil {
		// TODO: parse the error code and only create if it's a `NotFound` error
		// assume it doesn't exists, go and create it
		opts := ec2.SecurityGroup{
			Name:        groupName,
			Description: "Koding VMs group",
			VpcId:       vpcId,
		}

		resp, err := m.Session.AWSClient.Client.CreateSecurityGroup(opts)
		if err != nil {
			return nil, err
		}

		// Authorize the SSH and Klient access
		perms := []ec2.IPPerm{
			ec2.IPPerm{
				Protocol:  "tcp",
				FromPort:  0,
				ToPort:    65535,
				SourceIPs: []string{"0.0.0.0/0"},
			},
		}

		group = resp.SecurityGroup

		// TODO: use retry mechanism
		// We loop and retry this a few times because sometimes the security
		// group isn't available immediately because AWS resources are eventaully
		// consistent.
		for i := 0; i < 5; i++ {
			_, err = m.Session.AWSClient.Client.AuthorizeSecurityGroup(group, perms)
			if err == nil {
				break
			}

			m.Log.Error("Error authorizing. Will sleep and retry. %s", err)
			time.Sleep((time.Duration(i) * time.Second) + 1)
		}

		if err != nil {
			return nil, err
		}

	}

	m.Session.AWSClient.Builder.KeyPair = keys.KeyName
	m.Session.AWSClient.Builder.PrivateKey = keys.PrivateKey
	m.Session.AWSClient.Builder.PublicKey = keys.PublicKey

	keyName, err := m.Session.AWSClient.DeployKey()
	if err != nil {
		return nil, err
	}

	ec2Data := &ec2.RunInstances{
		ImageId:                  m.Meta.SourceAmi,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  keyName,
		InstanceType:             m.Session.AWSClient.Builder.InstanceType,
		SubnetId:                 subnetId,
		SecurityGroups:           []ec2.SecurityGroup{{Id: group.Id}},
		AssociatePublicIpAddress: true,
		BlockDevices:             []ec2.BlockDeviceMapping{imageData.blockDeviceMapping},
		UserData:                 userdata,
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

	tags := []ec2.Tag{
		{Key: "Name", Value: m.Meta.InstanceName},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-env", Value: m.Session.Kite.Config.Environment},
		{Key: "koding-machineId", Value: m.Id.Hex()},
		{Key: "koding-domain", Value: m.Domain},
	}

	m.Log.Debug("Adding user tags %v", tags)
	if err := m.Session.AWSClient.AddTags(m.Meta.InstanceId, tags); err != nil {
		m.Log.Error("Adding tags failed: %v", err)
	}
}
