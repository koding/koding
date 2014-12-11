package koding

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"
	"time"

	"code.google.com/p/go.crypto/ssh"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"github.com/dgrijalva/jwt-go"
	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
	"gopkg.in/yaml.v2"
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
	EC2Data *ec2.RunInstances
	KiteId  string
}

type Build struct {
	amazon        *amazon.AmazonClient
	machine       *protocol.Machine
	provider      *Provider
	start, finish int
	log           logging.Logger
	retryCount    int
}

// normalize returns the normalized step according to the initial start and finish
// values. i.e for a start,finish pair of (10,90) percentages of
// 0,15,20,50,80,100 will be according to the function: 10,18,26,50,74,90
func (b *Build) normalize(percentage int) int {
	base := b.finish - b.start
	step := float64(base) * (float64(percentage) / 100)
	normalized := float64(b.start) + step
	return int(normalized)

}

func (p *Provider) Build(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	b := &Build{
		amazon:   a,
		machine:  m,
		provider: p,
		start:    10,
		finish:   90,
		log:      p.Log,
	}

	return b.run()
}

func (b *Build) run() (*protocol.Artifact, error) {
	var err error
	instanceId := b.amazon.Builder.InstanceId
	queryString := b.machine.QueryString

	// if there is already a machine just check it again
	if instanceId == "" {
		b.amazon.Push("Generating and fetching build data", b.normalize(10), machinestate.Building)
		b.log.Info("[%s] Generating and fetching build data", b.machine.Id)
		buildData, err := b.buildData()
		if err != nil {
			return nil, err
		}

		queryString = kiteprotocol.Kite{ID: buildData.KiteId}.String()

		b.amazon.Push("Checking limits and quota", b.normalize(20), machinestate.Building)
		b.log.Info("[%s] Checking user limitation and machine quotas", b.machine.Id)
		if err := b.checkLimits(buildData); err != nil {
			return nil, err
		}

		b.amazon.Push("Initiating build process", b.normalize(40), machinestate.Building)
		b.log.Info("[%s] Initiating creating process of instance", b.machine.Id)
		instanceId, err = b.create(buildData)
		if err != nil {
			return nil, err
		}

		// update the intermediate information
		b.provider.Update(b.machine.Id, &kloud.StorageData{
			Type: "building",
			Data: map[string]interface{}{
				"instanceId":  instanceId,
				"queryString": queryString,
				"region":      b.amazon.Builder.Region,
			},
		})
	} else {
		b.log.Info("[%s] Continue build process with data, instanceId: '%s' and queryString: '%s'",
			b.machine.Id, instanceId, queryString)
	}

	b.amazon.Push("Checking build process", b.normalize(50), machinestate.Building)
	b.log.Info("[%s] Checking build process of instanceId '%s'", b.machine.Id, instanceId)
	buildArtifact, err := b.checkBuild(instanceId)
	if err == amazon.ErrInstanceTerminated || err == amazon.ErrNoInstances {
		// reset the stored instance id and query string. They will be updated again the next time.
		b.log.Warning("[%s] machine with instance id '%s' has a problem '%s'. Building a new machine",
			b.machine.Id, instanceId, err)

		// we fallback to us-east-1 because a terminated or no instances error
		// only appears if the given region doesn't have any space left to
		// build instances, such as volume limites. Unfortunaly a
		// "RunInstances" doesn't return an error because that particular limit
		// is being displayed on the UI.
		b.amazon.Builder.InstanceId = ""
		b.machine.QueryString = ""
		b.amazon.Builder.Region = "us-east-1"

		client, err := b.provider.EC2Clients.Region("us-east-1")
		if err != nil {
			return nil, err
		}
		b.amazon.Client = client

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

	buildArtifact.KiteQuery = queryString

	b.log.Debug("Buildartifact is ready: %#v", buildArtifact)

	b.amazon.Push("Adding and setting up domains and tags", b.normalize(70), machinestate.Building)
	b.log.Info("[%s] Adding and setting up domain and tags", b.machine.Id)
	b.addDomainAndTags(buildArtifact)

	b.amazon.Push(fmt.Sprintf("Checking klient connection '%s'", buildArtifact.IpAddress),
		b.normalize(90), machinestate.Building)
	b.log.Info("[%s] All finished, testing for klient connection IP [%s]",
		b.machine.Id, buildArtifact.IpAddress)
	if err := b.checkKite(buildArtifact.KiteQuery); err != nil {
		return nil, err
	}

	return buildArtifact, nil
}

// buildData returns all necessary data that is needed to build a machine.
func (b *Build) buildData() (*BuildData, error) {
	// get all subnets belonging to Kloud
	b.log.Debug("[%s] Searching for subnet that are tagged with 'kloud-subnet-*'",
		b.machine.Id)
	subnets, err := b.amazon.SubnetsWithTag(DefaultKloudSubnetValue)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	b.log.Debug("[%s] Searching for security group for vpc id '%s'",
		b.machine.Id, subnet.VpcId)
	group, err := b.amazon.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	b.log.Debug("[%s] Fetching image which is tagged with '%s'",
		b.machine.Id, DefaultCustomAMITag)
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
	b.log.Debug("[%s] Using block device settings %v", b.machine.Id, blockDeviceMapping)

	b.log.Debug("[%s] Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		b.machine.Id, subnet.SubnetId, subnet.AvailabilityZone,
		group.Id, subnet.AvailableIpAddressCount)

	if b.amazon.Builder.InstanceType == "" {
		b.log.Critical("[%s] Instance type is empty. This shouldn't happen. Fallback to t2.micro",
			b.machine.Id)
		b.amazon.Builder.InstanceType = T2Micro.String()
	}

	kiteUUID, err := uuid.NewV4()
	if err != nil {
		return nil, err
	}

	kiteId := kiteUUID.String()

	b.log.Debug("[%s] Creating user data", b.machine.Id)
	userData, err := b.userData(kiteId)
	if err != nil {
		return nil, err
	}

	ec2Data := &ec2.RunInstances{
		ImageId:                  image.Id,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  b.provider.KeyName,
		InstanceType:             b.amazon.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SubnetId:                 subnet.SubnetId,
		SecurityGroups:           []ec2.SecurityGroup{{Id: group.Id}},
		AvailZone:                subnet.AvailabilityZone,
		BlockDevices:             []ec2.BlockDeviceMapping{blockDeviceMapping},
		UserData:                 userData,
	}

	return &BuildData{
		EC2Data: ec2Data,
		KiteId:  kiteId,
	}, nil
}

func (b *Build) userData(kiteId string) ([]byte, error) {
	kiteKey, err := b.createKey(b.machine.Username, kiteId)
	if err != nil {
		return nil, err
	}

	latestKlientPath, err := b.provider.Bucket.LatestDeb()
	if err != nil {
		return nil, err
	}

	latestKlientUrl := b.provider.Bucket.URL(latestKlientPath)

	// Use cloud-init for initial configuration of the VM
	cloudInitConfig := &CloudInitConfig{
		Username:        b.machine.Username,
		UserDomain:      b.machine.Domain.Name,
		Hostname:        b.machine.Username, // no typo here. hostname = username
		KiteKey:         kiteKey,
		LatestKlientURL: latestKlientUrl,
		ApachePort:      DefaultApachePort,
		KitePort:        DefaultKitePort,
	}

	// check if the user has some keys
	if keyData, ok := b.machine.Builder["user_ssh_keys"]; ok {
		if keys, ok := keyData.([]string); ok && len(keys) > 0 {
			for _, key := range keys {
				// validate the public keys
				_, _, _, _, err := ssh.ParseAuthorizedKey([]byte(key))
				if err != nil {
					b.log.Error(`User (%s) has an invalid public SSH key. Not adding it to the authorized keys. Key: %s. Err: %v`,
						b.machine.Username, key, err)
					continue
				}
				cloudInitConfig.UserSSHKeys = append(cloudInitConfig.UserSSHKeys, key)
			}
		}
	}

	var userdata bytes.Buffer
	err = cloudInitTemplate.Funcs(funcMap).Execute(&userdata, *cloudInitConfig)
	if err != nil {
		return nil, err
	}

	// validate the userdata first before sending
	if err = yaml.Unmarshal(userdata.Bytes(), struct{}{}); err != nil {
		// write to temporary file so we can see the yaml file that is not
		// formatted in a good way.
		f, err := ioutil.TempFile("", "kloud-cloudinit")
		if err == nil {
			if _, err := f.WriteString(userdata.String()); err != nil {
				b.log.Error("Cloudinit temporary field couldn't be written %v", err)
			}
		}

		b.log.Error("Cloudinit template is not a valid YAML file: %v. YAML file path: %s", err,
			f.Name())
		return nil, errors.New("Cloudinit template is not a valid YAML file.")
	}

	return userdata.Bytes(), nil

}

// checkLimits checks whether the given buildData is valid to be used to create a new instance
func (b *Build) checkLimits(buildData *BuildData) error {
	// Check for total machine allowance
	checker, err := b.provider.PlanChecker(b.machine)
	if err != nil {
		return err
	}

	if err := checker.Total(); err != nil {
		return err
	}

	if err := checker.AlwaysOn(); err != nil {
		return err
	}

	b.log.Debug("[%s] Check if user is allowed to create instance type %s",
		b.machine.Id, buildData.EC2Data.InstanceType)

	// check if the user is egligible to create a vm with this instance type
	if err := checker.AllowedInstances(instances[buildData.EC2Data.InstanceType]); err != nil {
		b.log.Critical("[%s] Instance type (%s) is not allowed. Fallback to t2.micro",
			b.machine.Id, buildData.EC2Data.InstanceType)
		buildData.EC2Data.InstanceType = T2Micro.String()
	}

	// check if the user is egligible to create a vm with this size
	if err := checker.Storage(int(buildData.EC2Data.BlockDevices[0].VolumeSize)); err != nil {
		return err
	}

	return nil
}

func (b *Build) create(buildData *BuildData) (string, error) {
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

	b.log.Error("[%s] IMPORTANT: %s", b.machine.Id, err)

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
		b.log.Debug("[%s] Fallback: Searching for a zone that has capacity amongst zones: %v", b.machine.Id, zones)
		for _, zone := range zones {
			if zone == currentZone {
				// skip it because that's one is causing problems and doesn't have any capacity
				continue
			}

			subnet, err := subnets.AvailabilityZone(zone)
			if err != nil {
				b.log.Critical("[%s] Fallback zone failed to get subnet zone '%s' ", err, b.machine.Id, zone)
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

			b.log.Warning("[%s] Fallback build by using availability zone: %s, subnet %s and instance type: %s",
				b.machine.Id, zone, subnet.SubnetId, instanceType)

			buildArtifact, err := b.amazon.Build(buildData.EC2Data)
			if err != nil {
				// if there is no capacity we are going to use the next one
				b.log.Warning("[%s] Build failed on availability zone '%s' due to AWS capacity problems. Trying another region.",
					b.machine.Id, zone)
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
			b.log.Critical("[%s] Fallback didn't work for instances: %s", b.machine.Id, err)
			continue // pick up the next instance type
		}

		return buildArtifact, nil
	}

	return "", errors.New("build reached the end. all fallback mechanism steps failed.")
}

func (b *Build) checkBuild(instanceId string) (*protocol.Artifact, error) {
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

func (b *Build) addDomainAndTags(buildArtifact *protocol.Artifact) {
	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	instanceName := b.machine.Builder["instanceName"].(string)
	if instanceName == "terminated-instance" {
		instanceName = "user-" + b.machine.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		b.log.Debug("[%s] Instance name is an artifact (terminated), changing to %s", b.machine.Id, instanceName)
	}

	b.amazon.Push("Updating/Creating domain", b.normalize(70), machinestate.Building)
	b.log.Debug("Updating/Creating domain %s", buildArtifact.IpAddress)

	if err := b.provider.UpdateDomain(buildArtifact.IpAddress, b.machine.Domain.Name, b.machine.Username); err != nil {
		b.log.Error("[%s] updating domains for setting err: %s", b.machine.Id, err.Error())
	}

	b.amazon.Push("Updating domain aliases", b.normalize(72), machinestate.Building)
	domains, err := b.provider.DomainStorage.GetByMachine(b.machine.Id)
	if err != nil {
		b.log.Error("[%s] fetching domains for setting err: %s", b.machine.Id, err.Error())
	}

	for _, domain := range domains {
		if err := b.provider.UpdateDomain(buildArtifact.IpAddress, domain.Name, b.machine.Username); err != nil {
			b.log.Error("[%s] couldn't update machine domain: %s", b.machine.Id, err.Error())
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

	b.log.Debug("[%s] Adding user tags %v", b.machine.Id, tags)
	if err := b.amazon.AddTags(buildArtifact.InstanceId, tags); err != nil {
		b.log.Error("[%s] Adding tags failed: %v", b.machine.Id, err)
	}
}

func (b *Build) checkKite(query string) error {
	b.log.Debug("[%s] Connecting to remote Klient instance", b.machine.Id)
	if b.provider.IsKlientReady(query) {
		b.log.Debug("[%s] klient is ready.", b.machine.Id)
	} else {
		b.log.Warning("[%s] klient is not ready. I couldn't connect to it.", b.machine.Id)
	}

	return nil
}

// CreateKey signs a new key and returns the token back
func (b *Build) createKey(username, kiteId string) (string, error) {
	if username == "" {
		return "", kloud.NewError(kloud.ErrSignUsernameEmpty)
	}

	if b.provider.KontrolURL == "" {
		return "", kloud.NewError(kloud.ErrSignKontrolURLEmpty)
	}

	if b.provider.KontrolPrivateKey == "" {
		return "", kloud.NewError(kloud.ErrSignPrivateKeyEmpty)
	}

	if b.provider.KontrolPublicKey == "" {
		return "", kloud.NewError(kloud.ErrSignPublicKeyEmpty)
	}

	token := jwt.New(jwt.GetSigningMethod("RS256"))

	token.Claims = map[string]interface{}{
		"iss":        "koding",                                       // Issuer, should be the same username as kontrol
		"sub":        username,                                       // Subject
		"iat":        time.Now().UTC().Unix(),                        // Issued At
		"jti":        kiteId,                                         // JWT ID
		"kontrolURL": b.provider.KontrolURL,                          // Kontrol URL
		"kontrolKey": strings.TrimSpace(b.provider.KontrolPublicKey), // Public key of kontrol
	}

	return token.SignedString([]byte(b.provider.KontrolPrivateKey))
}
