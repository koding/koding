package koding

import (
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/userdata"
	"koding/kites/kloud/waitstate"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/fatih/structs"
	kiteprotocol "github.com/koding/kite/protocol"
	uuid "github.com/satori/go.uuid"
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
		"t2.nano",
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
		SnapshotId string
		Reason     string
	}

	err = req.Args.One().Unmarshal(&args)
	if err != nil {
		return err
	}

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	if args.SnapshotId != "" {
		meta.SnapshotId = args.SnapshotId
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

	if meta.InstanceName == "" {
		meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	// Keep track of whether or not this build process is creating a new
	// instanceId, or creating a pre-existing image.
	var creatingNewInstance bool

	// if there is already a machine just check it again
	if meta.InstanceId == "" {
		creatingNewInstance = true

		m.push("Generating and fetching build data", 10, machinestate.Building)

		m.Log.Debug("Generating and fetching build data")
		buildData, err := m.buildData(ctx)
		if err != nil {
			return err
		}

		instanceType, ok := m.convertInstanceType(buildData)
		if ok {
			buildData.EC2Data.InstanceType = aws.String(instanceType)
			m.Meta["instance_type"] = instanceType
		}

		meta.SourceAmi = buildData.ImageData.imageID
		m.QueryString = kiteprotocol.Kite{ID: buildData.KiteId}.String()

		m.push("Checking limits and quota", 20, machinestate.Building)
		m.Log.Debug("Checking user limitation and machine quotas")
		// TODO: move out checking facility outwards machine and put it into kloud
		if err := m.checkLimits(buildData); err != nil {
			return err
		}

		m.push("Initiating build process", 30, machinestate.Building)
		m.Log.Debug("Initiating creating process of instance")
		meta.InstanceId, err = m.create(buildData)
		if err != nil {
			return err
		}

		if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
			updatedFields := bson.M{
				"meta.instanceId": meta.InstanceId,
				"meta.source_ami": meta.SourceAmi,
				"meta.region":     meta.Region,
				"queryString":     m.QueryString,
			}

			if ok {
				updatedFields["meta.instance_type"] = instanceType
			}

			return c.UpdateId(m.ObjectId, bson.M{"$set": updatedFields})
		}); err != nil {
			return err
		}
	} else {
		m.Log.Debug("Continue build process with data, instanceId: %q and queryString: %q",
			meta.InstanceId, m.QueryString)

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
				"Failed to recover for pre-existing instance. (username: %q, instanceId: %q, region: %q)",
				m.Credential, meta.InstanceId, meta.Region,
			)
		}
	}

	m.push("Checking build process", 40, machinestate.Building)
	m.Log.Debug("Checking build process of instanceId %q", meta.InstanceId)

	// In the event that checkBuild fails, we can log to see how long it took
	// with this var.
	checkBuildStart := time.Now()
	instance, err := m.Session.AWSClient.CheckBuild(ctx, meta.InstanceId, 50, 70)
	checkBuildDur := time.Since(checkBuildStart)

	if err == amazon.ErrInstanceTerminated || amazon.IsNotFound(err) {
		// reset the stored instance id and query string. They will be updated again the next time.
		m.Log.Warning("machine with instance id %q has a problem %q. Building a new machine",
			meta.InstanceId, err)

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

		m.Meta = structs.Map(meta) // update meta

		// call it again recursively
		return m.Build(ctx)
	}

	// if it's something else return it!
	if err != nil {
		// In the event of a new instance and checkbuild failing, log more
		// verbose information for metrics.
		m.Log.Warning(
			"CheckBuild failed. (newInstance: %t, username: %s, instanceId: %s, region: %s, provider: %s, CheckBuild duration: %fs) err: %s",
			creatingNewInstance, m.Credential, meta.InstanceId,
			meta.Region, m.Provider, checkBuildDur.Seconds(), err,
		)

		return err
	}

	meta.InstanceType = aws.StringValue(instance.InstanceType)
	meta.SourceAmi = aws.StringValue(instance.ImageId)
	m.IpAddress = aws.StringValue(instance.PublicIpAddress)

	m.Meta = structs.Map(meta) // update meta

	// allocate and associate a new Public IP for paying users, we can do
	// this after we create the instance
	if plan, ok := plans.Plans[m.Payment.Plan]; ok && plan != plans.Free {
		m.Log.Debug("Paying user detected, Creating an Public Elastic IP")

		elasticIp, err := m.Session.AWSClient.AllocateAndAssociateIP(meta.InstanceId)
		if err != nil {
			m.Log.Warning("couldn't not create elastic IP: %s", err)
		} else {
			m.IpAddress = elasticIp
		}
	}

	m.push("Adding and setting up domains and tags", 70, machinestate.Building)

	if err := m.addDomainAndTags(); err != nil {
		return err
	}

	m.push(fmt.Sprintf("Checking klient connection '%s'", m.IpAddress), 80, machinestate.Building)
	if !m.isKlientReady() {
		return errors.New("klient is not ready")
	}

	resultInfo := fmt.Sprintf("username: [%s], instanceId: [%s], ipAdress: [%s], kiteQuery: [%s]",
		m.Username, meta.InstanceId, m.IpAddress, m.QueryString)

	m.Log.Info("========== BUILD results ========== %s", resultInfo)

	reason = "Machine is build successfully."
	if args.Reason != "" {
		reason += "Custom reason: " + args.Reason
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          m.IpAddress,
				"queryString":        m.QueryString,
				"meta.instance_type": meta.InstanceType,
				"meta.instanceName":  meta.InstanceName,
				"meta.instanceId":    meta.InstanceId,
				"meta.source_ami":    meta.SourceAmi,
				"status.state":       machinestate.Running.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      reason,
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
	if len(image.BlockDeviceMappings) == 0 {
		return nil, &amazon.NotFoundError{
			Resource: "BlockDeviceMapping",
			Err:      fmt.Errorf("no block device mapping found within image=%q", DefaultCustomAMITag),
		}
	}
	if len(image.BlockDeviceMappings) > 1 {
		m.Log.Warning("more than one block device mapping for image=%q: %+v", DefaultCustomAMITag, image.BlockDeviceMappings)
	}

	device := image.BlockDeviceMappings[0]

	storageSize := 3 // default AMI 3GB size
	if m.Session.AWSClient.Builder.StorageSize != 0 && m.Session.AWSClient.Builder.StorageSize > 3 {
		storageSize = m.Session.AWSClient.Builder.StorageSize
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	blockDeviceMapping := &ec2.BlockDeviceMapping{
		DeviceName:  device.DeviceName,
		VirtualName: device.VirtualName,
		Ebs: &ec2.EbsBlockDevice{
			VolumeType:          aws.String("standard"), // Use magnetic storage because it is cheaper
			VolumeSize:          aws.Int64(int64(storageSize)),
			DeleteOnTermination: aws.Bool(true),
		},
	}

	meta, err := m.GetMeta()
	if err != nil {
		return nil, err
	}

	// Before using the snapshot, Check if it exists. If it does not,
	// unset it.
	if meta.SnapshotId != "" {
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
				meta.SnapshotId)
			if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
				return c.UpdateId(
					m.ObjectId,
					bson.M{"$unset": bson.M{
						"meta.snapshotId": "",
					}},
				)
			}); err != nil {
				return nil, err
			}
			meta.SnapshotId = ""
		}
	}

	// The snapshot exists, create an AMI from it
	if meta.SnapshotId != "" {
		m.Log.Debug("creating AMI from the snapshot '%s'", meta.SnapshotId)

		blockDeviceMapping.Ebs.SnapshotId = aws.String(meta.SnapshotId)
		amiDesc := fmt.Sprintf("user-%s-%s", m.Username, m.ObjectId.Hex())

		registerOpts := &ec2.RegisterImageInput{
			Name:               aws.String(amiDesc),
			Description:        aws.String(amiDesc),
			Architecture:       image.Architecture,
			RootDeviceName:     image.RootDeviceName,
			VirtualizationType: image.VirtualizationType,
			KernelId:           image.KernelId,
			RamdiskId:          image.RamdiskId,
			BlockDeviceMappings: []*ec2.BlockDeviceMapping{
				blockDeviceMapping,
			},
		}

		imageID, err := m.Session.AWSClient.Client.RegisterImage(registerOpts)
		if err != nil {
			return nil, err
		}

		// if we build the instance from a snapshot, it'll create a temporary
		// AMI. Destroy it after we are finished or if something goes wrong.
		m.cleanFuncs = append(m.cleanFuncs, func() {
			m.Log.Debug("Deleting temporary AMI %q", imageID)
			if err := m.Session.AWSClient.Client.DeregisterImage(imageID); err != nil {
				m.Log.Warning("Couldn't delete AMI %q: %s", imageID, err)
			}
		})

		// wait until the AMI is ready
		checkAMI := func(currentPercentage int) (machinestate.State, error) {
			m.push("Checking ami", currentPercentage, machinestate.Building)

			image, err := m.Session.AWSClient.Client.ImageByID(imageID)
			if err != nil {
				return 0, err
			}

			if aws.StringValue(image.State) != "available" {
				return machinestate.Pending, nil
			}

			return machinestate.NotInitialized, nil
		}

		ws := waitstate.WaitState{
			StateFunc:    checkAMI,
			DesiredState: machinestate.NotInitialized,
		}

		if err := ws.Wait(); err != nil {
			return nil, err
		}

		image.ImageId = aws.String(imageID)
	}

	m.Log.Debug("Using image ObjectId: %q and block device settings %+v", aws.StringValue(image.ImageId), blockDeviceMapping)

	m.Meta = structs.Map(meta) // update meta

	return &ImageData{
		imageID:            aws.StringValue(image.ImageId),
		blockDeviceMapping: blockDeviceMapping,
	}, nil
}

func (m *Machine) convertInstanceType(data *BuildData) (string, bool) {
	switch {
	// Ensure instances for old free users or users that downgraded from paid
	// plan are converted from t2.micro to t2.nano.
	case plans.Plans[m.Payment.Plan] == plans.Free && aws.StringValue(data.EC2Data.InstanceType) != plans.T2Nano.String():
		return plans.T2Nano.String(), true
	default:
		return "", false
	}
}

// buildData returns all necessary data that is needed to build a machine.
func (m *Machine) buildData(ctx context.Context) (*BuildData, error) {
	// get all subnets belonging to Kloud
	m.Log.Debug("Searching for subnet that are tagged with %q", DefaultKloudSubnetValue)
	subnets, err := m.Session.AWSClient.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	m.Log.Debug("Searching for security group for vpc id %q", aws.StringValue(subnet.VpcId))
	group, err := m.Session.AWSClient.SecurityGroupFromVPC(aws.StringValue(subnet.VpcId), DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	imageData, err := m.imageData(ctx)
	if err != nil {
		return nil, err
	}

	m.Log.Debug("Using subnet: %q, zone: %q, sg: %q. Subnet has %d available IPs",
		aws.StringValue(subnet.SubnetId), aws.StringValue(subnet.AvailabilityZone),
		aws.StringValue(group.GroupId), aws.Int64Value(subnet.AvailableIpAddressCount))

	if m.Session.AWSClient.Builder.InstanceType == "" {
		m.Log.Critical("Instance type is empty. This shouldn't happen. Fallback to t2.nano",
			m.ObjectId.Hex())
		m.Session.AWSClient.Builder.InstanceType = plans.T2Nano.String()
	}

	kiteUUID := uuid.NewV4()

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

	ec2Data := &ec2.RunInstancesInput{
		ImageId:      aws.String(imageData.imageID),
		MinCount:     aws.Int64(1),
		MaxCount:     aws.Int64(1),
		InstanceType: aws.String(m.Session.AWSClient.Builder.InstanceType),
		NetworkInterfaces: []*ec2.InstanceNetworkInterfaceSpecification{{
			DeviceIndex: aws.Int64(0),
			SubnetId:    subnet.SubnetId,
			Groups:      []*string{group.GroupId},
			AssociatePublicIpAddress: aws.Bool(true),
		}},
		Placement: &ec2.Placement{
			AvailabilityZone: subnet.AvailabilityZone,
		},
		BlockDeviceMappings: []*ec2.BlockDeviceMapping{
			imageData.blockDeviceMapping,
		},
		UserData: aws.String(base64.StdEncoding.EncodeToString(userdata)),
	}

	// pass publicKey if only it's available
	keys, ok := publickeys.FromContext(ctx)
	if ok {
		ec2Data.KeyName = aws.String(keys.KeyName)
	}

	return &BuildData{
		EC2Data:   ec2Data,
		ImageData: imageData,
		KiteId:    kiteId,
	}, nil
}

// checkLimits checks whether the given buildData is valid to be used to create a new instance
func (m *Machine) checkLimits(buildData *BuildData) error {

	m.Log.Debug("Checking Total instances limits")
	if err := m.Checker.Total(m.Username); err != nil {
		return err
	}

	m.Log.Debug("Checking AlwaysOn requireement")
	if err := m.Checker.AlwaysOn(m.Username); err != nil {
		return err
	}

	m.Log.Debug("Check if user is allowed to create instance type %q", aws.StringValue(buildData.EC2Data.InstanceType))

	// check if the user is egligible to create a vm with this instance type
	if err := m.Checker.AllowedInstances(plans.Instances[aws.StringValue(buildData.EC2Data.InstanceType)]); err != nil {
		m.Log.Critical("Instance type %q is not allowed. Fallback to t2.nano", aws.StringValue(buildData.EC2Data.InstanceType))
		buildData.EC2Data.InstanceType = aws.String(plans.T2Nano.String())
	}

	wantSize := int(aws.Int64Value(buildData.EC2Data.BlockDeviceMappings[0].Ebs.VolumeSize))
	m.Log.Debug("Checking if user is eglible for a '%d' storage size", wantSize)
	// check if the user is egligible to create a vm with this size
	if err := m.Checker.Storage(wantSize, m.Username); err != nil {
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

	zones, err := m.Session.AWSClients.Zones(m.Session.AWSClient.Region)
	if err != nil {
		return "", err
	}

	subnets, err := m.Session.AWSClient.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return "", err
	}

	currentZone := aws.StringValue(buildData.EC2Data.Placement.AvailabilityZone)

	// tryAllZones will try to build the given instance type with in all zones
	// until it's succeed.
	tryAllZones := func(instanceType string) (string, error) {
		m.Log.Debug("Fallback: Searching for a zone that has capacity amongst zones: %+v", zones)
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

			group, err := m.Session.AWSClient.SecurityGroupFromVPC(aws.StringValue(subnet.VpcId), DefaultKloudKeyName)
			if err != nil {
				return "", err
			}

			// add now our security group
			buildData.EC2Data.InstanceType = aws.String(instanceType)
			buildData.EC2Data.NetworkInterfaces[0].Groups[0] = group.GroupId
			buildData.EC2Data.NetworkInterfaces[0].SubnetId = subnet.SubnetId
			buildData.EC2Data.Placement.AvailabilityZone = aws.String(zone)

			m.Log.Warning("Fallback build by using availability zone: %s, subnet %q and instance type: %s",
				zone, aws.StringValue(subnet.SubnetId), instanceType)

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

func (m *Machine) addDomainAndTags() error {
	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	m.Log.Debug("Adding and setting up domain and tags")
	if meta.InstanceName == "terminated-instance" {
		meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		m.Log.Debug("Instance name is an artifact (terminated), changing to %s", meta.InstanceName)
	}

	m.push("Updating/Creating domain", 70, machinestate.Building)
	m.Log.Debug("Updating/Creating domain %s", m.IpAddress)

	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	m.push("Updating domain aliases", 72, machinestate.Building)
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for setting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
			continue
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
	}

	tags := map[string]string{
		"Name":             meta.InstanceName,
		"koding-user":      m.Username,
		"koding-env":       m.Session.Kite.Config.Environment,
		"koding-machineId": m.ObjectId.Hex(),
		"koding-domain":    m.Domain,
	}

	m.Log.Debug("Adding user tags to instance=%q: %v", meta.InstanceId, tags)
	if err := m.Session.AWSClient.AddTags(meta.InstanceId, tags); err != nil {
		m.Log.Error("Adding tags failed: %s", err)
		return err
	}

	m.Meta = structs.Map(meta) // update meta

	return nil
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
	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// If there is no instanceId, we shouldn't be recovering from anything,
	// we should be creating the instance. Return an error.
	if meta.InstanceId == "" {
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

	awsState := amazon.StatusToState(aws.StringValue(instance.State.Name))
	switch awsState {
	// No action needed, build method expects these states
	case machinestate.Starting, machinestate.Running:

	// Start the machine, to let build continue like normal.
	case machinestate.Stopped:
		m.Log.Info(
			"Manually starting previously stopped instance. (username: %s, instanceId: %s, region: %s)",
			m.Credential, meta.InstanceId, meta.Region,
		)

		// We're calling the client start api directly, rather than
		// using `api/amazon.Start()` because we don't want or need to
		// wait for the vm to finish starting. The build method
		// already does that.
		//
		// Note that we are *not* locking here. The caller of this
		// is expected to be Kloud.Build, which will already have
		// this machine locked.
		_, err := m.Session.AWSClient.Client.StartInstance(m.Session.AWSClient.Id())
		if err != nil {
			return err
		}
	}

	return nil
}
