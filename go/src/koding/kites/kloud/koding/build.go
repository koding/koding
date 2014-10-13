package koding

import (
	"bytes"
	"errors"
	"io/ioutil"
	"sort"
	"strconv"
	"strings"
	"time"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"code.google.com/p/go.crypto/ssh"
	"github.com/dgrijalva/jwt-go"
	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
	"gopkg.in/yaml.v2"
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

	infoLog := p.GetCustomLogger(m.Id, "info")
	errLog := p.GetCustomLogger(m.Id, "error")

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
		errLog("Searching subnet err: %v", err)
		return nil, errors.New("searching network configuration failed")
	}

	// sort and get the lowest
	infoLog("Searching a subnet with most IPs amongst '%d' subnets", len(subnets))
	subnet := subnetWithMostIPs(subnets)

	infoLog("Using subnet id %s, which has %d available IPs", subnet.SubnetId, subnet.AvailableIpAddressCount)
	a.Builder.SubnetId = subnet.SubnetId

	infoLog("Checking if security group for VPC id %s exists.", subnet.VpcId)
	group, err := a.SecurityGroupFromVPC(subnet.VpcId, kloudKeyName)
	if err != nil {
		errLog("Checking security group err: %v", err)
		return nil, errors.New("checking security requirements failed")
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
		errLog("Checking ami tag failed err: %v", err)
		return nil, errors.New("checking base image failed")
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
		errLog("Checking klient S3 path failed: %v", err)
		return nil, errors.New("machine initialization requirements failed [1]")
	}

	latestKlientUrl := p.Bucket.URL(latestKlientPath)

	// Use cloud-init for initial configuration of the VM
	cloudInitConfig := &CloudInitConfig{
		Username:        m.Username,
		UserDomain:      m.Domain.Name,
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
			for _, key := range keys {
				// validate the public keys
				_, _, _, _, err := ssh.ParseAuthorizedKey([]byte(key))
				if err != nil {
					errLog(`User (%s) has an invalid public SSH key.
							Not adding it to the authorized keys.
							Key: %s. Err: %v`, m.Username, key, err)
					continue
				}
				cloudInitConfig.UserSSHKeys = append(cloudInitConfig.UserSSHKeys, key)
			}
		}
	}

	cloudInitConfig.setupMigrateScript()

	var userdata bytes.Buffer
	err = cloudInitTemplate.Funcs(funcMap).Execute(&userdata, *cloudInitConfig)
	if err != nil {
		errLog("Template execution failed: %v", err)
		return nil, errors.New("machine initialization requirements failed [2]")
	}

	// validate the userdata first before sending
	if err = yaml.Unmarshal(userdata.Bytes(), struct{}{}); err != nil {
		// write to temporary file so we can see the yaml file that is not
		// formatted in a good way.
		f, err := ioutil.TempFile("", "kloud-cloudinit")
		if err == nil {
			if _, err := f.WriteString(userdata.String()); err != nil {
				errLog("Cloudinit temporary field couldn't be written %v", err)
			}
		}

		errLog("Cloudinit template is not a valid YAML file: %v. YAML file path: %s", err,
			f.Name())
		return nil, errors.New("Cloudinit template is not a valid YAML file.")
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
			p.Log.Warning("Cleaning up instance '%s'. Terminating instance: %s. Error was: %s",
				instanceName, buildArtifact.InstanceId, err)

			if _, err := a.Client.TerminateInstances([]string{buildArtifact.InstanceId}); err != nil {
				p.Log.Warning("Cleaning up instance '%s' failed: %v", instanceName, err)
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
			if err := p.DNS.Delete(m.Domain.Name, buildArtifact.IpAddress); err != nil {
				p.Log.Warning("[%s] Cleaning up domain failed: %v", m.Id, err)
			}
		}
	}()

	a.Push("Updating domain aliases", normalize(72), machinestate.Building)
	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("[%s] fetching domains for setting err: %s", m.Id, err.Error())
	}

	for _, domain := range domains {
		if err := p.UpdateDomain(buildArtifact.IpAddress, domain.Name, m.Username); err != nil {
			p.Log.Error("[%s] couldn't update machine domain: %s", m.Id, err.Error())
		}
	}

	tags := []ec2.Tag{
		{Key: "Name", Value: buildArtifact.InstanceName},
		{Key: "koding-user", Value: m.Username},
		{Key: "koding-env", Value: p.Kite.Config.Environment},
		{Key: "koding-machineId", Value: m.Id},
		{Key: "koding-domain", Value: m.Domain.Name},
	}

	infoLog("Adding user tags %v", tags)
	if err := a.AddTags(buildArtifact.InstanceId, tags); err != nil {
		errLog("Adding tags failed: %v", err)
		return nil, errors.New("machine initialization requirements failed [3]")
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
