package koding

import (
	"bytes"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/koding/kloud/kloud"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
)

var (
	DefaultCustomAMITag = "koding-stable" // Only use AMI's that have this tag
	DefaultInstanceType = "t2.micro"
)

const (
	DefaultApachePort = 80
	DefaultKitePort   = 3000
)

func (p *Provider) Build(opts *protocol.Machine) (resArt *protocol.Artifact, err error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	username := opts.Builder["username"].(string)

	// Check for total amachine allowance
	checker, err := p.PlanChecker(opts)
	if err != nil {
		return nil, err
	}

	p.Log.Info("[%s] checking machine limit for user '%s'", opts.MachineId, username)
	if err := checker.Total(); err != nil {
		return nil, err
	}

	p.Log.Info("[%s] checking alwaysOn limit for user '%s'", opts.MachineId, username)
	if err := checker.AlwaysOn(); err != nil {
		return nil, err
	}

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	instanceName := opts.Builder["instanceName"].(string)

	a.Push("Initializing data", 10, machinestate.Building)

	infoLog := p.GetInfoLogger(opts.MachineId)

	a.InfoLog = infoLog

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	if instanceName == "terminated-instance" {
		instanceName = "user-" + username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		infoLog("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	a.Push("Checking security requirements", 20, machinestate.Building)

	groupName := "koding-kloud" // TODO: make it from the package level and remove it from here
	infoLog("Checking if security group '%s' exists", groupName)
	group, err := a.SecurityGroup(groupName)
	if err != nil {
		return nil, err
	}

	// add now our security group
	a.Builder.SecurityGroupId = group.Id

	// Use koding plans instead of those later
	a.Builder.InstanceType = DefaultInstanceType

	infoLog("Check if user is allowed to create instance type %s", a.Builder.InstanceType)
	// check if the user is egligible to create a vm with this size
	if err := checker.AllowedInstances(instances[a.Builder.InstanceType]); err != nil {
		return nil, err
	}

	// needed for vpc instances, go and grap one from one of our Koding's own
	// subnets
	infoLog("Searching for subnets")
	subs, err := a.ListSubnets()
	if err != nil {
		return nil, err
	}
	a.Builder.SubnetId = subs.Subnets[0].SubnetId

	a.Push("Checking base build image", 30, machinestate.Building)

	infoLog("Checking if AMI with tag '%s' exists", DefaultCustomAMITag)
	image, err := a.ImageByTag(DefaultCustomAMITag)
	if err != nil {
		return nil, err
	}

	// Use this ami id, which is going to be a stable one
	a.Builder.SourceAmi = image.Id

	storageSize := 3 // default AMI 3GB size
	if a.Builder.StorageSize != 0 && a.Builder.StorageSize > 3 {
		storageSize = a.Builder.StorageSize
	}

	infoLog("Check if user is allowed to create machine with '%dGB' storage", storageSize)
	// check if the user is egligible to create a vm with this size
	if err := checker.Storage(storageSize); err != nil {
		return nil, err
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	if a.Builder.StorageSize != 0 {
		for _, device := range image.BlockDevices {
			a.Builder.BlockDeviceMapping = &ec2.BlockDeviceMapping{
				DeviceName:          device.DeviceName,
				VirtualName:         device.VirtualName,
				SnapshotId:          device.SnapshotId,
				VolumeType:          device.VolumeType,
				VolumeSize:          int64(a.Builder.StorageSize),
				DeleteOnTermination: true,
				Encrypted:           false,
			}

			break
		}
	}

	kiteId, err := uuid.NewV4()
	if err != nil {
		panic(err)
	}

	kiteKey, err := p.createKey(username, kiteId.String())
	if err != nil {
		return nil, err
	}

	latestKlientURL, err := p.Bucket.LatestDeb()
	if err != nil {
		return nil, err
	}
	signedLatestKlientURL := p.Bucket.SignedURL(latestKlientURL, time.Now().Add(time.Minute*3))

	// Use cloud-init for initial configuration of the VM
	cloudInitConfig := &CloudInitConfig{
		Username:        username,
		Hostname:        username, // no typo here. hostname = username
		KiteKey:         kiteKey,
		LatestKlientURL: signedLatestKlientURL,
		ApachePort:      DefaultApachePort,
		KitePort:        DefaultKitePort,
	}

	cloudInitConfig.setupMigrateScript()

	var userdata bytes.Buffer
	err = cloudInitTemplate.Execute(&userdata, *cloudInitConfig)
	if err != nil {
		return nil, err
	}

	a.Builder.UserData = userdata.Bytes()

	// add our Koding keypair
	a.Builder.KeyPair = p.KeyName

	// build now our instance!!
	buildArtifact, err := a.Build(instanceName)
	if err != nil {
		return nil, err
	}
	buildArtifact.MachineId = opts.MachineId

	// cleanup build if something goes wrong here
	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up instance. Terminating instance: %s",
				opts.MachineId, buildArtifact.InstanceId)

			if _, err := a.Client.TerminateInstances([]string{buildArtifact.InstanceId}); err != nil {
				p.Log.Warning("[%s] Cleaning up instance failed: %v", opts.MachineId, err)
			}
		}
	}()

	a.Push("Checking domain", 65, machinestate.Building)

	a.Push("Creating domain", 70, machinestate.Building)
	if err := p.UpdateDomain(buildArtifact.IpAddress, machineData.Domain, username); err != nil {
		return nil, err
	}

	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up domain record. Deleting domain record: %s",
				opts.MachineId, machineData.Domain)
			if err := p.DNS.DeleteDomain(machineData.Domain, buildArtifact.IpAddress); err != nil {
				p.Log.Warning("[%s] Cleaning up domain failed: %v", opts.MachineId, err)
			}

		}
	}()

	tags := []ec2.Tag{
		{Key: "Name", Value: buildArtifact.InstanceName},
		{Key: "koding-user", Value: username},
		{Key: "koding-env", Value: p.Kite.Config.Environment},
		{Key: "koding-machineId", Value: opts.MachineId},
		{Key: "koding-domain", Value: machineData.Domain},
	}

	infoLog("Adding user tags %v", tags)
	if err := a.AddTags(buildArtifact.InstanceId, tags); err != nil {
		return nil, err
	}

	buildArtifact.DomainName = machineData.Domain

	query := kiteprotocol.Kite{ID: kiteId.String()}
	buildArtifact.KiteQuery = query.String()

	a.Push("Checking connectivity", 75, machinestate.Building)
	infoLog("Connecting to remote Klient instance")
	if p.IsKlientReady(query.String()) {
		p.Log.Info("[%s] klient is ready.", opts.MachineId)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", opts.MachineId)
	}

	return buildArtifact, nil
}

// CreateKey signs a new key and returns the token back
func (p *Provider) createKey(username, kiteId string) (string, error) {
	if username == "" {
		return "", kloud.NewError(kloud.ErrSignUsernameEmpty)
	}

	if p.KontrolURL == "" {
		return "", kloud.NewError(kloud.ErrSignKontrolURLEmpty)
	}

	if p.KontrolPrivateKey == "" {
		return "", kloud.NewError(kloud.ErrSignPrivateKeyEmpty)
	}

	if p.KontrolPublicKey == "" {
		return "", kloud.NewError(kloud.ErrSignPublicKeyEmpty)
	}

	token := jwt.New(jwt.GetSigningMethod("RS256"))

	token.Claims = map[string]interface{}{
		"iss":        "koding",                              // Issuer, should be the same username as kontrol
		"sub":        username,                              // Subject
		"iat":        time.Now().UTC().Unix(),               // Issued At
		"jti":        kiteId,                                // JWT ID
		"kontrolURL": p.KontrolURL,                          // Kontrol URL
		"kontrolKey": strings.TrimSpace(p.KontrolPublicKey), // Public key of kontrol
	}

	return token.SignedString([]byte(p.KontrolPrivateKey))
}
