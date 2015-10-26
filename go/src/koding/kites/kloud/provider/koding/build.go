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
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
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
	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not available")
	}

	// the user might send us a snapshot id
	var args struct {
		SnapshotId string
		Reason     string
	}

	err = req.Args.One().Unmarshal(&args)
	if err != nil {
		return err
	}

	if args.SnapshotId != "" {
		m.Meta.SnapshotId = args.SnapshotId
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

	// Keep track of whether or not this build process is creating a new
	// instanceId, or creating a pre-existing image.
	var creatingNewInstance bool

	// if there is already a machine just check it again
	if m.Meta.InstanceId == "" {
		creatingNewInstance = true

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
		// TODO: move out checking facility outwards machine and put it into kloud
		if err := m.checkLimits(buildData); err != nil {
			return err
		}

		m.push("Initiating build process", 30, machinestate.Building)
		m.Log.Debug("Initiating creating process of instance")
		m.Meta.InstanceId, err = m.create(buildData)
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

		// If this is not the first attempt to build, the first attempt may
		// have timed out or failed in some other way. To heal this and
		// continue the build normally, we call buildRecovery()
		if err := m.buildRecovery(); err != nil {
			// If there was an error during build recovery, we can log
			// it but we don't *need* to fail. The CheckBuild() usage
			// below will attempt to wait for a status from AWS for X minutes.
			//
			// AWS may return success within that timeframe, so if we return
			// an error here we do not give AWS a chance to return
			// successfully.
			m.Log.Warning(
				"Failed to recover for pre-existing instance. (username: %s, instanceId: %s, region: %s)",
				m.Credential, m.Meta.InstanceId, m.Meta.Region,
			)
		}

	}

	m.push("Checking build process", 40, machinestate.Building)
	m.Log.Debug("Checking build process of instanceId '%s'", m.Meta.InstanceId)

	// In the event that checkBuild fails, we can log to see how long it took
	// with this var.
	checkBuildStart := time.Now()
	instance, err := m.Session.AWSClient.CheckBuild(ctx, m.Meta.InstanceId, 50, 70)
	checkBuildDur := time.Since(checkBuildStart)

	if err == amazon.ErrInstanceTerminated || err == amazon.ErrNoInstances {
		// reset the stored instance id and query string. They will be updated again the next time.
		m.Log.Warning("machine with instance id '%s' has a problem '%s'. Building a new machine",
			m.Meta.InstanceId, err)

		// we fallback to us-east-1 (it has the largest quota) because a
		// terminated or no instances error only appears if the given region
		// doesn't have any space left to build instances, such as volume
		// limites. Unfortunaly a "RunInstances" doesn't return an error
		// because that particular limit is being displayed on the UI.
		if err := m.switchAWSRegion("us-east-1"); err != nil {
			return err
		}

		// check if we tried before, if not try again. Also do not panic for first time.
		retryCount, _ := ctx.Value("retryKey").(int)
		if retryCount == 3 {
			return errors.New("I've tried to build three times in row without any success")
		}
		retryCount++

		ctx = context.WithValue(ctx, "retryKey", retryCount) // increase

		// call it again recursively
		return m.Build(ctx)
	}

	// if it's something else return it!
	if err != nil {
		// In the event of a new instance and checkbuild failing, log more
		// verbose information for metrics.
		m.Log.Warning(
			"CheckBuild failed. (newInstance: %t, username: %s, instanceId: %s, region: %s, provider: %s, CheckBuild duration: %fs) err: %s",
			creatingNewInstance, m.Credential, m.Meta.InstanceId,
			m.Meta.Region, m.Provider, checkBuildDur.Seconds(), err.Error(),
		)

		return err
	}

	m.Meta.InstanceType = instance.InstanceType
	m.Meta.SourceAmi = instance.ImageId
	m.IpAddress = instance.PublicIpAddress

	// allocate and associate a new Public IP for paying users, we can do
	// this after we create the instance
	if m.Payment.Plan != "free" {
		m.Log.Debug("Paying user detected, Creating an Public Elastic IP")

		elasticIp, err := m.Session.AWSClient.AllocateAndAssociateIP(m.Meta.InstanceId)
		if err != nil {
			m.Log.Warning("couldn't not create elastic IP: %s", err)
		} else {
			m.IpAddress = elasticIp
		}
	}

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

func (m *Machine) imageData(ctx context.Context) (*ImageData, error) {
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

	// Before using the snapshot, Check if it exists. If it does not,
	// unset it.
	if m.Meta.SnapshotId != "" {
		m.Log.Debug("checking for snapshot permissions")
		// If the querying the snapshot returns an error, it may not exist,
		// or it may not be owned by the Machine's owner.
		exists, err := m.checkSnapshotExistence()
		if err != nil {
			return nil, err
		}

		// We need to know if the SnapshotId was populated from this
		// request, or if it was pre-existing in the JMachine document
		req, ok := request.FromContext(ctx)
		if !ok {
			return nil, errors.New("request context is not available")
		}

		var args struct {
			SnapshotId string
		}

		err = req.Args.One().Unmarshal(&args)
		if err != nil {
			return nil, err
		}

		// If the snapshotId does not exist, and it was not user supplied,
		// safely unset it from this Machine.
		if !exists {
			// If the SnapshotId was user supplied,
			// return an error.
			if args.SnapshotId != "" {
				return nil, errors.New("no snapshot found for the given user")
			}

			m.Log.Debug("SnapshotId '%s' not found, Removing it from the Machine",
				m.Meta.SnapshotId)
			if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
				return c.UpdateId(
					m.Id,
					bson.M{"$unset": bson.M{
						"meta.snapshotId": "",
					}},
				)
			}); err != nil {
				return nil, err
			}
			m.Meta.SnapshotId = ""
		}
	}

	// The snapshot exists, create an AMI from it
	if m.Meta.SnapshotId != "" {
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
		m.cleanFuncs = append(m.cleanFuncs, func() {
			m.Log.Debug("Deleting temporary AMI '%s'", registerResp.ImageId)
			if _, err := m.Session.AWSClient.Client.DeregisterImage(registerResp.ImageId); err != nil {
				m.Log.Warning("Couldn't delete AMI '%s': %s", registerResp.ImageId, err)
			}
		})

		// wait until the AMI is ready
		checkAMI := func(currentPercentage int) (machinestate.State, error) {
			m.push("Checking ami", currentPercentage, machinestate.Building)

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

		ws := waitstate.WaitState{StateFunc: checkAMI, DesiredState: machinestate.NotInitialized}
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

	imageData, err := m.imageData(ctx)
	if err != nil {
		return nil, err
	}

	m.Log.Debug("Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		subnet.SubnetId, subnet.AvailabilityZone, group.Id, subnet.AvailableIpAddressCount)

	if m.Session.AWSClient.Builder.InstanceType == "" {
		m.Log.Critical("Instance type is empty. This shouldn't happen. Fallback to t2.micro",
			m.Id.Hex())
		m.Session.AWSClient.Builder.InstanceType = plans.T2Micro.String()
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
		Username:           m.Username,
		Groups:             []string{"docker", "sudo"},
		UserSSHKeys:        sshKeys,
		Hostname:           m.Username, // no typo here. hostname = username
		KiteId:             kiteId,
		DisableEC2MetaData: true,
		KodingSetup:        true,
	}

	userdata, err := m.Session.Userdata.Create(cloudInitConfig)
	if err != nil {
		return nil, err
	}

	ec2Data := &ec2.RunInstances{
		ImageId:                  imageData.imageId,
		MinCount:                 1,
		MaxCount:                 1,
		InstanceType:             m.Session.AWSClient.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SubnetId:                 subnet.SubnetId,
		SecurityGroups:           []ec2.SecurityGroup{{Id: group.Id}},
		AvailZone:                subnet.AvailabilityZone,
		BlockDevices:             []ec2.BlockDeviceMapping{imageData.blockDeviceMapping},
		UserData:                 userdata,
	}

	// pass publicKey if only it's available
	keys, ok := publickeys.FromContext(ctx)
	if ok {
		ec2Data.KeyName = keys.KeyName
	}

	return &BuildData{
		EC2Data:   ec2Data,
		ImageData: imageData,
		KiteId:    kiteId,
	}, nil
}

// checkLimits checks whether the given buildData is valid to be used to create a new instance
func (m *Machine) checkLimits(buildData *BuildData) error {
	if err := m.Checker.Total(m.Username); err != nil {
		return err
	}

	if err := m.Checker.AlwaysOn(m.Username); err != nil {
		return err
	}

	m.Log.Debug("Check if user is allowed to create instance type %s", buildData.EC2Data.InstanceType)

	// check if the user is egligible to create a vm with this instance type
	if err := m.Checker.AllowedInstances(plans.Instances[buildData.EC2Data.InstanceType]); err != nil {
		m.Log.Critical("Instance type (%s) is not allowed. Fallback to t2.micro",
			buildData.EC2Data.InstanceType)
		buildData.EC2Data.InstanceType = plans.T2Micro.String()
	}

	// check if the user is egligible to create a vm with this size
	if err := m.Checker.Storage(int(buildData.EC2Data.BlockDevices[0].VolumeSize), m.Username); err != nil {
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

			instanceId, err := m.Session.AWSClient.Build(buildData.EC2Data)
			if err != nil {
				// if there is no capacity we are going to use the next one
				m.Log.Warning("Build failed on availability zone '%s' due to AWS capacity problems. Trying another region.",
					zone)
				continue
			}

			return instanceId, nil // we got something that works!
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
		instanceId, err := tryAllZones(instanceType)
		if err != nil {
			m.Log.Critical("Fallback didn't work for instances: %s", err)
			continue // pick up the next instance type
		}

		return instanceId, nil
	}

	return "", errors.New("build reached the end. all fallback mechanism steps failed.")
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

// buildRecovery attempts to get the status of the machine from AWS
// and handle any oddities that may have came up during any previous
// build processes.
//
// It does not inherently handle all edge cases, but simply the ones we
// expect. For reference, the following URL describes the AWS API
// endpoint for the initial creation of an ec2 instance:
//
// http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RunInstances.html
//
// The following scenarios are currently handled and/or expected:
//
// 1. Stopped (stopped): An AWS status of Stopped typically means that
// 	the build process failed last time, and the machine was eventually
// 	turned off. In this event, we must make a Start call. We do need
// 	to wait for the machine to finish starting, as the normal
// 	`Kloud.Build()` methods handle that - recovery just starts it.
// 2. Starting (pending): An AWS status of Pending typically means that
// 	the machine is still building from its initial attempt, and is
// 	being retried by the user. No action is needed.
// 3. Running (running): An AWS state of Running typically means that
// 	the machine building was completed. No action is needed.
func (m *Machine) buildRecovery() error {
	// If there is no instanceId, we shouldn't be recovering from anything,
	// we should be creating the instance. Return an error.
	if m.Meta.InstanceId == "" {
		return errors.New(
			"buildRecovery: Unable to recover from build if InstanceId has not been created",
		)
	}

	instance, err := m.Session.AWSClient.Instance()

	// If we fail to get the instance, there's nothing we can do
	// for recovery.
	if err != nil {
		return err
	}

	awsState := amazon.StatusToState(instance.State.Name)
	switch awsState {
	// No action needed, build method expects these states
	case machinestate.Starting, machinestate.Running:

	// Start the machine, to let build continue like normal.
	case machinestate.Stopped:
		m.Log.Info(
			"Manually starting previously stopped instance. (username: %s, instanceId: %s, region: %s)",
			m.Credential, m.Meta.InstanceId, m.Meta.Region,
		)

		// We're calling the client start api directly, rather than
		// using `api/amazon.Start()` because we don't want or need to
		// wait for the vm to finish starting. The build method
		// already does that.
		//
		// Note that we are *not* locking here. The caller of this
		// is expected to be Kloud.Build, which will already have
		// this machine locked.
		_, err := m.Session.AWSClient.Client.StartInstances(
			m.Session.AWSClient.Id(),
		)
		if err != nil {
			return err
		}
	}

	return nil
}
