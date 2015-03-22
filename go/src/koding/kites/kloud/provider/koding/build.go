package koding

import (
	"errors"
	"fmt"
	"strconv"
	"time"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/userdata"
	"koding/kites/kloud/waitstate"

	"github.com/koding/logging"
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

type Build struct {
	amazon        *amazon.Amazon
	machine       *protocol.Machine
	provider      *Provider
	start, finish int
	log           logging.Logger
	retryCount    int
	plan          Plan
	checker       *PlanChecker

	// if available, create the instance via the snapshot -> AMI way
	snapshotId string

	// cleanFuncs are a list of functions that are called once a run() method
	// is returned (for an error or non error doesn't matter)
	cleanFuncs []func()
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

	if m.Meta.InstanceName == "" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	fmt.Println("building!")

	var err error
	imageId := ""
	instanceId := m.Meta.InstanceId

	// if there is already a machine just check it again
	if instanceId == "" {
		m.push("Generating and fetching build data", b.normalize(10), machinestate.Building)

		m.Log.Debug("Generating and fetching build data")
		buildData, err := b.buildData()
		if err != nil {
			return nil, err
		}

		imageId = buildData.ImageData.imageId
		queryString = kiteprotocol.Kite{ID: buildData.KiteId}.String()

		m.push("Checking limits and quota", b.normalize(20), machinestate.Building)
		m.Log.Debug("Checking user limitation and machine quotas")
		if err := b.checkLimits(buildData); err != nil {
			return nil, err
		}

		m.push("Initiating build process", b.normalize(40), machinestate.Building)
		m.Log.Debug("Initiating creating process of instance")
		instanceId, err = b.create(buildData)
		if err != nil {
			return nil, err
		}

		// update the intermediate information
		b.provider.Update(b.machine.Id, &kloud.StorageData{
			Type: "building",
			Data: map[string]interface{}{
				"instanceId":  instanceId,
				"imageId":     imageId,
				"queryString": queryString,
				"region":      m.Region,
			},
		})
	} else {
		m.Log.Debug("Continue build process with data, instanceId: '%s' and queryString: '%s'",
			instanceId, queryString)
	}

	m.push("Checking build process", b.normalize(50), machinestate.Building)
	m.Log.Debug("Checking build process of instanceId '%s'", instanceId)
	buildArtifact, err := m.checkBuild(instanceId)
	if err == amazon.ErrInstanceTerminated || err == amazon.ErrNoInstances {
		// reset the stored instance id and query string. They will be updated again the next time.
		m.Log.Warning("machine with instance id '%s' has a problem '%s'. Building a new machine",
			instanceId, err)

		// we fallback to us-east-1 because a terminated or no instances error
		// only appears if the given region doesn't have any space left to
		// build instances, such as volume limites. Unfortunaly a
		// "RunInstances" doesn't return an error because that particular limit
		// is being displayed on the UI.
		m.Meta.InstanceId = ""
		m.QueryString = ""
		m.Meta.Region = "us-east-1"

		client, err := b.provider.EC2Clients.Region("us-east-1")
		if err != nil {
			return nil, err
		}
		m.Session.AWSClient = client

		b.provider.Update(b.machine.Id, &kloud.StorageData{
			Type: "building",
			Data: map[string]interface{}{
				"instanceId":  "",
				"queryString": "",
				"region":      "us-east-1",
			},
		})

		if b.retryCount == 3 {
			return nil, errors.New("I've tried to build three times in row without any success")
		}
		b.retryCount++

		// call it again recursively
		return b.run()
	}

	// if it's something else return it!
	if err != nil {
		return nil, err
	}

	// allocate and associate a new Public IP for paying users, we can do
	// this after we create the instance
	if m.Payment.Plan != Free {
		m.Log.Debug("Paying user detected, Creating an Public Elastic IP")

		elasticIp, err := allocateAndAssociateIP(b.amazon.Client, instanceId)
		if err != nil {
			m.Log.Warning("couldn't not create elastic IP: %s", err)
		} else {
			buildArtifact.IpAddress = elasticIp
		}
	}

	buildArtifact.KiteQuery = queryString
	buildArtifact.ImageId = imageId

	m.Log.Debug("Buildartifact is ready: %#v", buildArtifact)

	m.push("Adding and setting up domains and tags", b.normalize(70), machinestate.Building)
	m.Log.Debug("Adding and setting up domain and tags")
	m.addDomainAndTags(buildArtifact)

	m.push(fmt.Sprintf("Checking klient connection '%s'", buildArtifact.IpAddress),
		b.normalize(90), machinestate.Building)
	m.Log.Debug("All finished, testing for klient connection IP [%s]", buildArtifact.IpAddress)
	if err := m.checkKite(buildArtifact.KiteQuery); err != nil {
		return nil, err
	}

	return buildArtifact, nil
}

func (m *Machine) imageData() (*ImageData, error) {
	m.Log.Debug("Fetching image which is tagged with '%s'", DefaultCustomAMITag)
	image, err := b.amazon.ImageByTag(DefaultCustomAMITag)
	if err != nil {
		return nil, err
	}

	device := image.BlockDevices[0]

	storageSize := 3 // default AMI 3GB size
	if b.amazon.Builder.StorageSize != 0 && b.amazon.Builder.StorageSize > 3 {
		storageSize = b.amazon.Builder.StorageSize
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

	if b.snapshotId != "" {
		m.Log.Debug("checking for snapshot permissions")
		// check first if the snapshot belongs to the user, it might belong to someone else!
		if err := b.provider.CheckSnapshotExistence(b.machine.Username, b.snapshotId); err != nil {
			return nil, err
		}

		m.Log.Debug("creating AMI from the snapshot '%s'", b.snapshotId)

		blockDeviceMapping.SnapshotId = b.snapshotId
		amiDesc := fmt.Sprintf("user-%s-%s", b.machine.Username, b.machine.Id)

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

		registerResp, err := b.amazon.Client.RegisterImage(registerOpts)
		if err != nil {
			return nil, err
		}

		// if we build the instance from a snapshot, it'll create a temporary
		// AMI. Destroy it after we are finished or if something goes wrong.
		b.cleanFuncs = append(b.cleanFuncs, func() {
			m.Log.Debug("Deleting temporary AMI '%s'", registerResp.ImageId)
			if _, err := b.amazon.Client.DeregisterImage(registerResp.ImageId); err != nil {
				m.Log.Warning("Couldn't delete AMI '%s': %s", registerResp.ImageId, err)
			}
		})

		// wait until the AMI is ready
		checkAMI := func(currentPercentage int) (machinestate.State, error) {
			resp, err := b.amazon.Client.Images([]string{registerResp.ImageId}, ec2.NewFilter())
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
func (m *Machine) buildData() (*BuildData, error) {
	// get all subnets belonging to Kloud
	m.Log.Debug("Searching for subnet that are tagged with 'kloud-subnet-*'")
	subnets, err := b.amazon.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	m.Log.Debug("Searching for security group for vpc id '%s'", subnet.VpcId)
	group, err := b.amazon.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	imageData, err := b.imageData()
	if err != nil {
		return nil, err
	}

	m.Log.Debug("Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		subnet.SubnetId, subnet.AvailabilityZone, group.Id, subnet.AvailableIpAddressCount)

	if b.amazon.Builder.InstanceType == "" {
		m.Log.Critical("Instance type is empty. This shouldn't happen. Fallback to t2.micro",
			b.machine.Id)
		b.amazon.Builder.InstanceType = T2Micro.String()
	}

	kiteUUID, err := uuid.NewV4()
	if err != nil {
		return nil, err
	}

	kiteId := kiteUUID.String()

	m.Log.Debug("Creating user data")

	sshKeys := make([]string, len(m.User.SshKeys))
	for i, key := range m.User.SshKeys {
		sshKeys[i] = key
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

	ec2Data := &ec2.RunInstances{
		ImageId:                  imageData.imageId,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  b.provider.KeyName,
		InstanceType:             b.amazon.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SubnetId:                 subnet.SubnetId,
		SecurityGroups:           []ec2.SecurityGroup{{Id: group.Id}},
		AvailZone:                subnet.AvailabilityZone,
		BlockDevices:             []ec2.BlockDeviceMapping{imageData.blockDeviceMapping},
		UserData:                 userData,
	}

	return &BuildData{
		EC2Data:   ec2Data,
		ImageData: imageData,
		KiteId:    kiteId,
	}, nil
}

// checkLimits checks whether the given buildData is valid to be used to create a new instance
func (m *Machine) checkLimits(buildData *BuildData) error {
	if err := b.checker.Total(); err != nil {
		return err
	}

	if err := b.checker.AlwaysOn(); err != nil {
		return err
	}

	m.Log.Debug("Check if user is allowed to create instance type %s", buildData.EC2Data.InstanceType)

	// check if the user is egligible to create a vm with this instance type
	if err := b.checker.AllowedInstances(instances[buildData.EC2Data.InstanceType]); err != nil {
		m.Log.Critical("Instance type (%s) is not allowed. Fallback to t2.micro",
			buildData.EC2Data.InstanceType)
		buildData.EC2Data.InstanceType = T2Micro.String()
	}

	// check if the user is egligible to create a vm with this size
	if err := b.checker.Storage(int(buildData.EC2Data.BlockDevices[0].VolumeSize)); err != nil {
		return err
	}

	return nil
}

func (m *Machine) create(buildData *BuildData) (string, error) {
	// build our instance in a normal way, if it's succeed just return
	instanceId, err := b.amazon.Build(buildData.EC2Data)
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

	zones, err := b.provider.EC2Clients.Zones(b.amazon.Client.Region.Name)
	if err != nil {
		return "", err
	}

	subnets, err := b.amazon.SubnetsWithTag(DefaultKloudSubnetValue)
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

			group, err := b.amazon.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
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

			buildArtifact, err := b.amazon.Build(buildData.EC2Data)
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
	instance, err := b.amazon.CheckBuild(instanceId, b.normalize(50), b.normalize(70))
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
	instanceName := b.machine.Builder["instanceName"].(string)
	if instanceName == "terminated-instance" {
		instanceName = "user-" + b.machine.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		m.Log.Debug("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	m.push("Updating/Creating domain", b.normalize(70), machinestate.Building)
	m.Log.Debug("Updating/Creating domain %s", buildArtifact.IpAddress)

	if err := b.provider.UpdateDomain(buildArtifact.IpAddress, b.machine.Domain.Name, b.machine.Username); err != nil {
		m.Log.Error("updating domains for setting err: %s", err.Error())
	}

	m.push("Updating domain aliases", b.normalize(72), machinestate.Building)
	domains, err := b.provider.DomainStorage.GetByMachine(b.machine.Id)
	if err != nil {
		m.Log.Error("fetching domains for setting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := b.provider.UpdateDomain(buildArtifact.IpAddress, domain.Name, b.machine.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
	}

	buildArtifact.InstanceName = instanceName
	buildArtifact.MachineId = b.machine.Id
	buildArtifact.DomainName = b.machine.Domain.Name

	tags := []ec2.Tag{
		{Key: "Name", Value: buildArtifact.InstanceName},
		{Key: "koding-user", Value: b.machine.Username},
		{Key: "koding-env", Value: b.provider.Kite.Config.Environment},
		{Key: "koding-machineId", Value: b.machine.Id},
		{Key: "koding-domain", Value: b.machine.Domain.Name},
	}

	m.Log.Debug("Adding user tags %v", tags)
	if err := b.amazon.AddTags(buildArtifact.InstanceId, tags); err != nil {
		m.Log.Error("Adding tags failed: %v", err)
	}
}

func (m *Machine) checkKite(query string) error {
	m.Log.Debug("Connecting to remote Klient instance")
	if b.provider.IsKlientReady(query) {
		m.Log.Debug("klient is ready.")
	} else {
		m.Log.Warning("klient is not ready. I couldn't connect to it.")
	}

	return nil
}

// push pushes the given message to the eventer
func (m *Machine) push(msg string, percentage int, state machinestate.State) (err error) {
	if m.Session.Eventer != nil {
		m.Session.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: percentage,
			Status:     state,
		})
	}
}

// normalize returns the normalized step according to the initial start and finish
// values. i.e for a start,finish pair of (10,90) percentages of
// 0,15,20,50,80,100 will be according to the function: 10,18,26,50,74,90
func (m *Machine) normalize(percentage int) int {
	base := b.finish - b.start
	step := float64(base) * (float64(percentage) / 100)
	normalized := float64(b.start) + step
	return int(normalized)

}
