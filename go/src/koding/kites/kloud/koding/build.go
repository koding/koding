package koding

import (
	"bytes"
	"sort"
	"strconv"
	"strings"
	"time"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"github.com/dgrijalva/jwt-go"
	kiteprotocol "github.com/koding/kite/protocol"
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

func (p *Provider) Build(m *protocol.Machine) (resArt *protocol.Artifact, err error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return p.build(a, m, &pushValues{Start: 10, Finish: 90})
}

func (p *Provider) build(a *amazon.AmazonClient, m *protocol.Machine, v *pushValues) (resArt *protocol.Artifact, err error) {
	// returns the normalized step according to the initial start and finish
	// values. i.e for a start,finish pair of (10,90) percentages of
	// 0,15,20,50,80,100 will be according to the function: 10,18,26,50,74,90
	normalize := func(percentage int) int {
		base := v.Finish - v.Start
		step := float64(base) * (float64(percentage) / 100)
		normalized := float64(v.Start) + step
		return int(normalized)
	}

	// Check for total amachine allowance
	checker, err := p.PlanChecker(m)
	if err != nil {
		return nil, err
	}

	p.Log.Info("[%s] checking machine limit for user '%s'", m.Id, m.Username)
	if err := checker.Total(); err != nil {
		return nil, err
	}

	p.Log.Info("[%s] checking alwaysOn limit for user '%s'", m.Id, m.Username)
	if err := checker.AlwaysOn(); err != nil {
		return nil, err
	}

	instanceName := m.Builder["instanceName"].(string)

	a.Push("Initializing data", normalize(10), machinestate.Building)

	infoLog := p.GetInfoLogger(m.Id)

	a.InfoLog = infoLog

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	if instanceName == "terminated-instance" {
		instanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		infoLog("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	a.Push("Checking network requirements", normalize(20), machinestate.Building)

	// get all subnets belonging to Kloud
	kloudKeyName := "Kloud"
	infoLog("Searching for subnets with tag-key %s", kloudKeyName)
	subnets, err := a.SubnetsWithTag(kloudKeyName)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	infoLog("Searching a subnet with most IPs amongst '%d' subnets", len(subnets))
	subnet := subnetWithMostIPs(subnets)

	infoLog("Using subnet id %s, which has %d available IPs", subnet.SubnetId, subnet.AvailableIpAddressCount)
	a.Builder.SubnetId = subnet.SubnetId

	infoLog("Checking if security group for VPC id %s exists.", subnet.VpcId)
	group, err := a.SecurityGroupFromVPC(subnet.VpcId, kloudKeyName)
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

	a.Push("Checking base build image", normalize(30), machinestate.Building)

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

	kiteKey, err := p.createKey(m.Username, kiteId.String())
	if err != nil {
		return nil, err
	}

	latestKlientPath, err := p.Bucket.LatestDeb()
	if err != nil {
		return nil, err
	}

	latestKlientUrl := p.Bucket.URL(latestKlientPath)

	// Use cloud-init for initial configuration of the VM
	cloudInitConfig := &CloudInitConfig{
		Username:        m.Username,
		Hostname:        m.Username, // no typo here. hostname = username
		KiteKey:         kiteKey,
		LatestKlientURL: latestKlientUrl,
		ApachePort:      DefaultApachePort,
		KitePort:        DefaultKitePort,
		Test:            p.Test,
	}

	// check if the user has some keys
	if keyData, ok := m.Builder["user_ssh_keys"]; ok {
		if keys, ok := keyData.([]string); ok && len(keys) > 0 {
			cloudInitConfig.UserSSHKeys = keys
		}
	}

	cloudInitConfig.setupMigrateScript()

	var userdata bytes.Buffer
	err = cloudInitTemplate.Funcs(funcMap).Execute(&userdata, *cloudInitConfig)
	if err != nil {
		return nil, err
	}

	// user data is now ready!
	a.Builder.UserData = userdata.Bytes()

	// add our Koding keypair
	a.Builder.KeyPair = p.KeyName

	// build now our instance!!
	buildArtifact, err := a.Build(instanceName, normalize(45), normalize(60))
	if err != nil {
		return nil, err
	}
	buildArtifact.MachineId = m.Id

	// cleanup build if something goes wrong here
	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up instance. Terminating instance: %s",
				m.Id, buildArtifact.InstanceId)

			if _, err := a.Client.TerminateInstances([]string{buildArtifact.InstanceId}); err != nil {
				p.Log.Warning("[%s] Cleaning up instance failed: %v", m.Id, err)
			}
		}
	}()

	a.Push("Updating/Creating domain", normalize(70), machinestate.Building)
	if err := p.UpdateDomain(buildArtifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		return nil, err
	}

	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up domain record. Deleting domain record: %s",
				m.Id, m.Domain.Name)
			if err := p.DNS.DeleteDomain(m.Domain.Name, buildArtifact.IpAddress); err != nil {
				p.Log.Warning("[%s] Cleaning up domain failed: %v", m.Id, err)
			}

		}
	}()

	tags := []ec2.Tag{
		{Key: "Name", Value: buildArtifact.InstanceName},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-env", Value: p.Kite.Config.Environment},
		{Key: "koding-machineId", Value: m.Id},
		{Key: "koding-domain", Value: m.Domain.Name},
	}

	infoLog("Adding user tags %v", tags)
	if err := a.AddTags(buildArtifact.InstanceId, tags); err != nil {
		return nil, err
	}

	buildArtifact.DomainName = m.Domain.Name

	query := kiteprotocol.Kite{ID: kiteId.String()}
	buildArtifact.KiteQuery = query.String()

	a.Push("Checking connectivity", normalize(75), machinestate.Building)
	infoLog("Connecting to remote Klient instance")
	if p.IsKlientReady(query.String()) {
		p.Log.Info("[%s] klient is ready.", m.Id)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
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

type ByMostIP []ec2.Subnet

func (a ByMostIP) Len() int      { return len(a) }
func (a ByMostIP) Swap(i, j int) { a[i], a[j] = a[j], a[i] }
func (a ByMostIP) Less(i, j int) bool {
	return a[i].AvailableIpAddressCount > a[j].AvailableIpAddressCount
}

func subnetWithMostIPs(subnets []ec2.Subnet) ec2.Subnet {
	sort.Sort(ByMostIP(subnets))
	return subnets[0]
}
