package koding

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
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/userdata"
	"koding/kites/kloud/waitstate"

	kiteprotocol "github.com/koding/kite/protocol"

	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
	"golang.org/x/net/context"
)

const (
	DefaultKloudSubnetValue = "kloud-subnet-*"
	DefaultKloudKeyName     = "Kloud"
	DefaultApachePort       = 80
	DefaultKitePort         = 3000
)

var (
	DefaultCustomAMITag = "koding-stable" // Only use AMI's that have this tag

	// Starting from cheapest, list is according to us-east and coming from:
	// http://www.ec2instances.info/. Only supported types are here.
	InstancesList = []string{
		"t2.micro",
		"t2.small",
		"t2.medium",
		"m3.medium",
		"c3.large",
		"m3.large",
		"c3.xlarge",
	}
)

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
	return m.runMethod(ctx, m.build)
}

func (m *Machine) build(ctx context.Context) error {
	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not available")
	}

	// the user might send us a snapshot id
	var args struct {
		SnapshotId string
	}

	if err := req.Args.One().Unmarshal(&args); err != nil {
		return err
	}

	if args.SnapshotId != "" {
		m.Meta.SnapshotId = args.SnapshotId
	}

	if m.Meta.InstanceName == "" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	fmt.Println("building!")

	var err error
	imageId := ""
	instanceId := m.Meta.InstanceId

	// if there is already a machine just check it again
	if instanceId == "" {
		m.push("Generating and fetching build data", 10, machinestate.Building)

		m.Log.Debug("Generating and fetching build data")
		buildData, err := m.buildData(ctx)
		if err != nil {
			return err
		}

		m.Meta.SourceAmi = buildData.ImageData.imageId
		m.QueryString = kiteprotocol.Kite{ID: buildData.KiteId}.String()

		m.push("Checking limits and quota", 20, machinestate.Building)
		m.Log.Debug("Checking user limitation and machine quotas")
		if err := m.checkLimits(buildData); err != nil {
			return err
		}

		m.push("Initiating build process", 30, machinestate.Building)
		m.Log.Debug("Initiating creating process of instance")
		instanceId, err = m.create(buildData)
		if err != nil {
			return err
		}

		if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				m.Id,
				bson.M{"$set": bson.M{
					"meta.instanceId": instanceId,
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
			instanceId, m.QueryString)
	}

	m.push("Checking build process", 50, machinestate.Building)
	m.Log.Debug("Checking build process of instanceId '%s'", instanceId)
	buildArtifact, err := m.checkBuild(instanceId)
	if err == amazon.ErrInstanceTerminated || err == amazon.ErrNoInstances {
		// reset the stored instance id and query string. They will be updated again the next time.
		m.Log.Warning("machine with instance id '%s' has a problem '%s'. Building a new machine",
			instanceId, err)

		// we fallback to us-east-1 (it has the largest quota) because a
		// terminated or no instances error only appears if the given region
		// doesn't have any space left to build instances, such as volume
		// limites. Unfortunaly a "RunInstances" doesn't return an error
		// because that particular limit is being displayed on the UI.
		if err := m.switchAWSRegion("us-east-1"); err != nil {
			return err
		}

		if b.retryCount == 3 {
			return errors.New("I've tried to build three times in row without any success")
		}
		b.retryCount++

		// call it again recursively
		return m.build(ctx)
	}

	// if it's something else return it!
	if err != nil {
		return err
	}

	// allocate and associate a new Public IP for paying users, we can do
	// this after we create the instance
	if m.Payment.Plan != Free {
		m.Log.Debug("Paying user detected, Creating an Public Elastic IP")

		elasticIp, err := m.Session.AWSClient.AllocateAndAssociateIP(instanceId)
		if err != nil {
			m.Log.Warning("couldn't not create elastic IP: %s", err)
		} else {
			buildArtifact.IpAddress = elasticIp
		}
	}

	buildArtifact.KiteQuery = m.QueryString
	buildArtifact.ImageId = imageId

	m.Log.Debug("Buildartifact is ready: %#v", buildArtifact)

	m.push("Adding and setting up domains and tags", 70, machinestate.Building)
	m.Log.Debug("Adding and setting up domain and tags")
	m.addDomainAndTags(buildArtifact)

	m.push(fmt.Sprintf("Checking klient connection '%s'", buildArtifact.IpAddress), 90, machinestate.Building)
	m.Log.Debug("All finished, testing for klient connection IP [%s]", buildArtifact.IpAddress)

	panic("TODO: update buildartifact information to MongoDB")

	return m.checkKite(buildArtifact.KiteQuery)
}

func (m *Machine) imageData() (*ImageData, error) {
	m.Log.Debug("Fetching image which is tagged with '%s'", DefaultCustomAMITag)
	image, err := m.Session.AWSClient.ImageByTag(DefaultCustomAMITag)
	if err != nil {
		return nil, err
	}

	device := image.BlockDevices[0]

	storageSize := 3 // default AMI 3GB size
	if m.Session.AWSClient.Builder.StorageSize != 0 && m.Session.AWSClient.Builder.StorageSize > 3 {
		storageSize = m.Session.AWSClient.Builder.StorageSize
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	blockDeviceMapping := ec2.BlockDeviceMapping{
		DeviceName:          device.DeviceName,
		VirtualName:         device.VirtualName,
		VolumeType:          "standard", // Use magnetic storage because it is cheaper
		VolumeSize:          int64(storageSize),
		DeleteOnTermination: true,
		Encrypted:           false,
	}

	if m.Meta.SnapshotId != "" {
		m.Log.Debug("checking for snapshot permissions")
		// check first if the snapshot belongs to the user, it might belong to someone else!
		if err := m.CheckSnapshotExistence(); err != nil {
			return nil, err
		}

		m.Log.Debug("creating AMI from the snapshot '%s'", m.Meta.SnapshotId)

		blockDeviceMapping.SnapshotId = m.Meta.SnapshotId
		amiDesc := fmt.Sprintf("user-%s-%s", m.Username, m.Id.Hex())

		registerOpts := &ec2.RegisterImage{
			Name:           amiDesc,
			Description:    amiDesc,
			Architecture:   image.Architecture,
			RootDeviceName: image.RootDeviceName,
			VirtType:       image.VirtualizationType,
			KernelId:       image.KernelId,
			RamdiskId:      image.RamdiskId,
			BlockDevices:   []ec2.BlockDeviceMapping{blockDeviceMapping},
		}

		registerResp, err := m.Session.AWSClient.Client.RegisterImage(registerOpts)
		if err != nil {
			return nil, err
		}

		// if we build the instance from a snapshot, it'll create a temporary
		// AMI. Destroy it after we are finished or if something goes wrong.
		b.cleanFuncs = append(b.cleanFuncs, func() {
			m.Log.Debug("Deleting temporary AMI '%s'", registerResp.ImageId)
			if _, err := m.Session.AWSClient.Client.DeregisterImage(registerResp.ImageId); err != nil {
				m.Log.Warning("Couldn't delete AMI '%s': %s", registerResp.ImageId, err)
			}
		})

		// wait until the AMI is ready
		checkAMI := func(currentPercentage int) (machinestate.State, error) {
			resp, err := m.Session.AWSClient.Client.Images([]string{registerResp.ImageId}, ec2.NewFilter())
			if err != nil {
				return 0, err
			}

			// shouldn't happen but let's check it anyway
			if len(resp.Images) == 0 {
				return machinestate.Pending, nil
			}

			image := resp.Images[0]
			if image.State != "available" {
				return machinestate.Pending, nil
			}

			return machinestate.NotInitialized, nil
		}

		ws := waitstate.WaitState{StateFunc: checkAMI, Action: "check-ami"}
		if err := ws.Wait(); err != nil {
			return nil, err
		}

		image.Id = registerResp.ImageId
	}

	m.Log.Debug("Using image Id: %s and block device settings %v", image.Id, blockDeviceMapping)

	return &ImageData{
		imageId:            image.Id,
		blockDeviceMapping: blockDeviceMapping,
	}, nil
}

// buildData returns all necessary data that is needed to build a machine.
func (m *Machine) buildData(ctx context.Context) (*BuildData, error) {
	// get all subnets belonging to Kloud
	m.Log.Debug("Searching for subnet that are tagged with 'kloud-subnet-*'")
	subnets, err := m.Session.AWSClient.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	m.Log.Debug("Searching for security group for vpc id '%s'", subnet.VpcId)
	group, err := m.Session.AWSClient.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	imageData, err := m.imageData()
	if err != nil {
		return nil, err
	}

	m.Log.Debug("Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		subnet.SubnetId, subnet.AvailabilityZone, group.Id, subnet.AvailableIpAddressCount)

	if m.Session.AWSClient.Builder.InstanceType == "" {
		m.Log.Critical("Instance type is empty. This shouldn't happen. Fallback to t2.micro",
			m.Id.Hex())
		m.Session.AWSClient.Builder.InstanceType = T2Micro.String()
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
		UserSSHKeys: sshKeys,
		UserDomain:  m.Domain,
		Hostname:    m.Username, // no typo here. hostname = username
		ApachePort:  DefaultApachePort,
		KitePort:    DefaultKitePort,
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

	ec2Data := &ec2.RunInstances{
		ImageId:                  imageData.imageId,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  keys.KeyName,
		InstanceType:             m.Session.AWSClient.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SubnetId:                 subnet.SubnetId,
		SecurityGroups:           []ec2.SecurityGroup{{Id: group.Id}},
		AvailZone:                subnet.AvailabilityZone,
		BlockDevices:             []ec2.BlockDeviceMapping{imageData.blockDeviceMapping},
		UserData:                 userdata,
	}

	return &BuildData{
		EC2Data:   ec2Data,
		ImageData: imageData,
		KiteId:    kiteId,
	}, nil
}

// checkLimits checks whether the given buildData is valid to be used to create a new instance
func (m *Machine) checkLimits(buildData *BuildData) error {
	if err := m.Total(); err != nil {
		return err
	}

	if err := m.AlwaysOn(); err != nil {
		return err
	}

	m.Log.Debug("Check if user is allowed to create instance type %s", buildData.EC2Data.InstanceType)

	// check if the user is egligible to create a vm with this instance type
	if err := m.AllowedInstances(instances[buildData.EC2Data.InstanceType]); err != nil {
		m.Log.Critical("Instance type (%s) is not allowed. Fallback to t2.micro",
			buildData.EC2Data.InstanceType)
		buildData.EC2Data.InstanceType = T2Micro.String()
	}

	// check if the user is egligible to create a vm with this size
	if err := m.Storage(int(buildData.EC2Data.BlockDevices[0].VolumeSize)); err != nil {
		return err
	}

	return nil
}

func (m *Machine) create(buildData *BuildData) (string, error) {
	// build our instance in a normal way, if it's succeed just return
	instanceId, err := m.Session.AWSClient.Build(buildData.EC2Data)
	if err == nil {
		return instanceId, nil
	}

	// check if the error is a 'InsufficientInstanceCapacity" error or
	// "InstanceLimitExceeded, if not return back because it's not a
	// resource or capacity problem.
	if !isCapacityError(err) {
		return "", err
	}

	m.Log.Error("IMPORTANT: %s", err)

	zones, err := m.Session.AWSClients.Zones(m.Session.AWSClient.Client.Region.Name)
	if err != nil {
		return "", err
	}

	subnets, err := m.Session.AWSClient.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return "", err
	}

	currentZone := buildData.EC2Data.AvailZone

	// tryAllZones will try to build the given instance type with in all zones
	// until it's succeed.
	tryAllZones := func(instanceType string) (string, error) {
		m.Log.Debug("Fallback: Searching for a zone that has capacity amongst zones: %v", zones)
		for _, zone := range zones {
			if zone == currentZone {
				// skip it because that's one is causing problems and doesn't have any capacity
				continue
			}

			subnet, err := subnets.AvailabilityZone(zone)
			if err != nil {
				m.Log.Critical("Fallback zone failed to get subnet zone '%s' ", err, zone)
				continue // shouldn't be happen, but let be safe
			}

			group, err := m.Session.AWSClient.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
			if err != nil {
				return "", err
			}

			// add now our security group
			buildData.EC2Data.SecurityGroups = []ec2.SecurityGroup{{Id: group.Id}}
			buildData.EC2Data.AvailZone = zone
			buildData.EC2Data.SubnetId = subnet.SubnetId
			buildData.EC2Data.InstanceType = instanceType

			m.Log.Warning("Fallback build by using availability zone: %s, subnet %s and instance type: %s",
				zone, subnet.SubnetId, instanceType)

			buildArtifact, err := m.Session.AWSClient.Build(buildData.EC2Data)
			if err != nil {
				// if there is no capacity we are going to use the next one
				m.Log.Warning("Build failed on availability zone '%s' due to AWS capacity problems. Trying another region.",
					zone)
				continue
			}

			return buildArtifact, nil // we got something that works!
		}

		return "", errors.New("tried all zones without any success.")
	}

	// Try to build the instance in another zone. We try to build one instance
	// type for all zones until all zones capacity is drained. In that case we
	// move on to the next instance type and start to use with all available
	// zones. This assures us that to fully use all zones with all instance
	// types and ensure a safe build.
	// TODO: filter out instances that are lower than the current user's
	// instance type (so don't pick up t2.small if the user hasa t2.medium)
	for _, instanceType := range InstancesList {
		buildArtifact, err := tryAllZones(instanceType)
		if err != nil {
			m.Log.Critical("Fallback didn't work for instances: %s", err)
			continue // pick up the next instance type
		}

		return buildArtifact, nil
	}

	return "", errors.New("build reached the end. all fallback mechanism steps failed.")
}

func (m *Machine) checkBuild(instanceId string) (*protocol.Artifact, error) {
	instance, err := m.Session.AWSClient.CheckBuild(instanceId, 50, 70)
	if err != nil {
		return nil, err
	}

	return &protocol.Artifact{
		IpAddress:    instance.PublicIpAddress,
		InstanceId:   instance.InstanceId,
		InstanceType: instance.InstanceType,
	}, nil

}

func (m *Machine) addDomainAndTags(buildArtifact *protocol.Artifact) {
	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	instanceName := m.Meta.InstanceName
	if instanceName == "terminated-instance" {
		instanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		m.Log.Debug("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	m.push("Updating/Creating domain", 70, machinestate.Building)
	m.Log.Debug("Updating/Creating domain %s", buildArtifact.IpAddress)

	if err := m.Session.DNS.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	if err := m.Session.DNS.Upsert(m.Domain, buildArtifact.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	m.push("Updating domain aliases", 72, machinestate.Building)
	domains, err := m.DomainsById()
	if err != nil {
		m.Log.Error("fetching domains for setting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.Session.DNS.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
		if err := m.Session.DNS.Upsert(domain.Name, buildArtifact.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
	}

	buildArtifact.InstanceName = instanceName
	buildArtifact.MachineId = m.Id.Hex()
	buildArtifact.DomainName = m.Domain

	tags := []ec2.Tag{
		{Key: "Name", Value: buildArtifact.InstanceName},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-env", Value: m.Session.Kite.Config.Environment},
		{Key: "koding-machineId", Value: m.Id.Hex()},
		{Key: "koding-domain", Value: m.Domain},
	}

	m.Log.Debug("Adding user tags %v", tags)
	if err := m.Session.AWSClient.AddTags(buildArtifact.InstanceId, tags); err != nil {
		m.Log.Error("Adding tags failed: %v", err)
	}
}

func (m *Machine) checkKite(query string) error {
	m.Log.Debug("Connecting to remote Klient instance")
	if m.isKlientReady() {
		m.Log.Debug("klient is ready.")
	} else {
		m.Log.Warning("klient is not ready. I couldn't connect to it.")
	}

	return nil
}

func (m *Machine) isKlientReady() bool {
	klientRef, err := klient.NewWithTimeout(m.Session.Kite, m.QueryString, time.Minute*2)
	if err != nil {
		m.Log.Warning("Connecting to remote Klient instance err: %s", err)
		return false
	}

	defer klientRef.Close()
	m.Log.Debug("Sending a ping message")
	if err := klientRef.Ping(); err != nil {
		m.Log.Debug("Sending a ping message err:", err)
		return false
	}

	return true
}

// push pushes the given message to the eventer
func (m *Machine) push(msg string, percentage int, state machinestate.State) {
	if m.Session.Eventer != nil {
		m.Session.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: percentage,
			Status:     state,
		})
	}
}

// // normalize returns the normalized step according to the initial start and finish
// // values. i.e for a start,finish pair of (10,90) percentages of
// // 0,15,20,50,80,100 will be according to the function: 10,18,26,50,74,90
// func (m *Machine) normalize(percentage int) int {
// 	base := b.finish - b.start
// 	step := float64(base) * (float64(percentage) / 100)
// 	normalized := float64(b.start) + step
// 	return int(normalized)
//
// }

func isCapacityError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false // return back if it's not an ec2.Error type
	}

	fallbackErrors := []string{
		"InsufficientInstanceCapacity",
		"InstanceLimitExceeded",
	}

	// check wether the incoming error code is one of the fallback
	// errors
	for _, fbErr := range fallbackErrors {
		if ec2Error.Code == fbErr {
			return true
		}
	}

	// return for non fallback errors, because we can't do much
	// here and probably it's need a more tailored solution
	return false
}

func isAddressNotFoundError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false
	}

	return ec2Error.Code == "InvalidAddress.NotFound"
}
