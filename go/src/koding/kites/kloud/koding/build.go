package koding

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
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

	// Starting from cheapest, list is according to us-east and coming from:
	// http://www.ec2instances.info/. t2.micro is not included because it's
	// already the default type which we start to build. Only supported types
	// are here.
	InstancesList = []string{
		"t2.small",
		"t2.medium",
		"m3.medium",
		"c3.large",
		"m3.large",
		"c3.xlarge",
	}
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

	errLog := p.GetCustomLogger(m.Id, "error")
	debugLog := p.GetCustomLogger(m.Id, "debug")

	// Check for total amachine allowance
	checker, err := p.PlanChecker(m)
	if err != nil {
		return nil, err
	}

	if err := checker.Total(); err != nil {
		errLog("Checking total machine err: %s", err)
		return nil, err
	}

	if err := checker.AlwaysOn(); err != nil {
		errLog("Checking always on limit err: %s", err)
		return nil, err
	}

	debugLog("build is using region: '%s'", m.Id, a.Builder.Region)

	a.Push("Initializing data", normalize(10), machinestate.Building)

	a.Push("Checking network requirements", normalize(20), machinestate.Building)

	// get all subnets belonging to Kloud
	kloudKeyName := "Kloud"
	subnets, err := a.SubnetsWithTag(kloudKeyName)
	if err != nil {
		errLog("Searching subnet err: %v", err)
		return nil, errors.New("searching network configuration failed")
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	group, err := a.SecurityGroupFromVPC(subnet.VpcId, kloudKeyName)
	if err != nil {
		errLog("Checking security group err: %v", err)
		return nil, errors.New("checking security requirements failed")
	}

	a.Builder.SecurityGroupId = group.Id
	a.Builder.SubnetId = subnet.SubnetId
	a.Builder.Zone = subnet.AvailabilityZone

	debugLog("Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		subnet.SubnetId, subnet.AvailabilityZone, group.Id, subnet.AvailableIpAddressCount)

	debugLog("Check if user is allowed to create instance type %s", a.Builder.InstanceType)

	if a.Builder.InstanceType == "" {
		a.Log.Critical("[%s] Instance type is empty. This shouldn't happen. Fallback to t2.micro", m.Id)
		a.Builder.InstanceType = T2Micro.String()
	}

	// check if the user is egligible to create a vm
	if err := checker.AllowedInstances(instances[a.Builder.InstanceType]); err != nil {
		a.Log.Critical("[%s] Instance type (%s) is not allowed. This shouldn't happen. Fallback to t2.micro", m.Id, a.Builder.InstanceType)
		a.Builder.InstanceType = T2Micro.String()
	}

	a.Push("Checking base build image", normalize(30), machinestate.Building)

	debugLog("Checking if AMI with tag '%s' exists", DefaultCustomAMITag)
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

	// check if the user is egligible to create a vm with this size
	if err := checker.Storage(storageSize); err != nil {
		errLog("Checking storage size failed err: %v", err)
		return nil, err
	}

	device := image.BlockDevices[0]

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	a.Builder.BlockDeviceMapping = &ec2.BlockDeviceMapping{
		DeviceName:          device.DeviceName,
		VirtualName:         device.VirtualName,
		SnapshotId:          device.SnapshotId,
		VolumeType:          "standard", // Use magnetic storage because it is cheaper
		VolumeSize:          int64(a.Builder.StorageSize),
		DeleteOnTermination: true,
		Encrypted:           false,
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

	var buildArtifact *protocol.Artifact
	buildFunc := func() error {
		// build our instance in a normal way
		buildArtifact, err = a.BuildWithCheck(normalize(45), normalize(60))
		if err == nil {
			return nil
		}

		// check if the error is a 'InsufficientInstanceCapacity" error or
		// "InstanceLimitExceeded, if not return back because it's not a
		// resource or capacity problem.
		if !isCapacityError(err) {
			return err
		}

		p.Log.Error("[%s] IMPORTANT: %s", m.Id, err)

		// now lets to some fallback mechanisms to avoid the capacity errors.
		// 1. Try to use a different zone
		zoneFunc := func() error {
			zones, err := p.EC2Clients.Zones(a.Client.Region.Name)
			if err != nil {
				return fmt.Errorf("couldn't fetch availability zones: %s", err)

			}

			currentZone := subnet.AvailabilityZone

			debugLog("Fallback: Searching for a zone that has capacity amongst zones: %v", zones)
			for _, zone := range zones {
				if zone == currentZone {
					// skip it because that's one is causing problems and doesn't have any capacity
					continue
				}

				subnet, err := subnets.AvailabilityZone(zone)
				if err != nil {
					continue // shouldn't be happen, but let be safe
				}

				group, err := a.SecurityGroupFromVPC(subnet.VpcId, kloudKeyName)
				if err != nil {
					errLog("Checking security group err: %v", err)
					return errors.New("checking security requirements failed")
				}

				// add now our security group
				a.Builder.SecurityGroupId = group.Id
				a.Builder.Zone = zone
				a.Builder.SubnetId = subnet.SubnetId

				p.Log.Warning("[%s] Building again by using availability zone: %s and subnet %s.",
					m.Id, zone, a.Builder.SubnetId)

				buildArtifact, err = a.Build(true, normalize(60), normalize(70))
				if err == nil {
					return nil
				}

				if isCapacityError(err) {
					// if there is no capacity we are going to use the next one
					p.Log.Warning("[%s] Build failed on availability zone '%s' due to AWS capacity problems. Trying another region.",
						m.Id, zone)
					continue
				}

				return err
			}

			return errors.New("no other zones are available")
		}

		// 2. Try to build it on another region
		regionFunc := func() error {
			return &ec2.Error{Code: "InsufficientInstanceCapacity", Message: "not implemented yet"}
		}

		// 3. Try to use another instance
		// TODO: do not choose an instance lower than the current user
		// instance. Currently all we give is t2.micro, however it if the user
		// has a t2.medium, we'll give them a t2.small if there is no capacity,
		// which needs to be fixed in the near future.
		instanceFunc := func() error {
			for _, instanceType := range InstancesList {
				a.Builder.InstanceType = instanceType

				p.Log.Warning("[%s] Fallback: building again with using instance: %s instead of %s.",
					m.Id, instanceType, a.Builder.InstanceType)

				buildArtifact, err = a.Build(true, normalize(60), normalize(70))
				if err == nil {
					return nil // we are finished!
				}

				p.Log.Warning("[%s] Fallback: couldn't build instance with type: '%s'. err: %s ",
					m.Id, instanceType, err)
			}

			return errors.New("no other instances are available")
		}

		// We are going to to try each step and for each step if we get
		// "InsufficentInstanceCapacity" error we move to the next one.
		for _, fn := range []func() error{zoneFunc, regionFunc, instanceFunc} {
			if err := fn(); err != nil {
				p.Log.Error("Build failed. Moving to next fallback step: %s", err)
				continue // pick up the next function
			}

			return nil
		}

		return errors.New("build reached the end. all fallback mechanism steps failed.")
	}

	// kabalaba booom!
	if err := buildFunc(); err != nil {
		return nil, err
	}

	// cleanup build if something goes wrong here
	defer func() {
		if err != nil {
			p.Log.Warning("Cleaning up instance by terminating instance: %s. Error was: %s",
				buildArtifact.InstanceId, err)

			if _, err := a.Client.TerminateInstances([]string{buildArtifact.InstanceId}); err != nil {
				p.Log.Warning("Cleaning up instance '%s' failed: %v", buildArtifact.InstanceId, err)
			}
		}
	}()

	buildArtifact.MachineId = m.Id

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	instanceName := m.Builder["instanceName"].(string)
	if instanceName == "terminated-instance" {
		instanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		debugLog("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	buildArtifact.InstanceName = instanceName

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

	debugLog("Adding user tags %v", tags)
	if err := a.AddTags(buildArtifact.InstanceId, tags); err != nil {
		errLog("Adding tags failed: %v", err)
		return nil, errors.New("machine initialization requirements failed [3]")
	}

	buildArtifact.DomainName = m.Domain.Name

	query := kiteprotocol.Kite{ID: kiteId.String()}
	buildArtifact.KiteQuery = query.String()

	a.Push("Checking connectivity", normalize(75), machinestate.Building)

	debugLog("Connecting to remote Klient instance")
	if p.IsKlientReady(query.String()) {
		debugLog("klient is ready.", m.Id)
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
