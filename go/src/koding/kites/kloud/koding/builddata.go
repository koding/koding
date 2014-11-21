package koding

import (
	"bytes"
	"errors"
	"io/ioutil"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"
	"strings"
	"time"

	"code.google.com/p/go.crypto/ssh"

	"github.com/dgrijalva/jwt-go"
	"github.com/mitchellh/goamz/ec2"
	"github.com/nu7hatch/gouuid"
	"gopkg.in/yaml.v2"
)

var DefaultCustomAMITag = "koding-stable" // Only use AMI's that have this tag

const (
	DefaultKloudKeyName = "Kloud"
	DefaultApachePort   = 80
	DefaultKitePort     = 3000
)

type BuildData struct {
	// This is passed directly to goamz to create the final instance
	EC2Data *ec2.RunInstances
	KiteId  string
}

func (p *Provider) buildData(a *amazon.AmazonClient, m *protocol.Machine) (*BuildData, error) {
	// get all subnets belonging to Kloud
	subnets, err := a.SubnetsWithTag(DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	// sort and get the lowest
	subnet := subnets.WithMostIps()

	group, err := a.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
	if err != nil {
		return nil, err
	}

	image, err := a.ImageByTag(DefaultCustomAMITag)
	if err != nil {
		return nil, err
	}

	device := image.BlockDevices[0]

	storageSize := 3 // default AMI 3GB size
	if a.Builder.StorageSize != 0 && a.Builder.StorageSize > 3 {
		storageSize = a.Builder.StorageSize
	}

	// Increase storage if it's passed to us, otherwise the default 3GB is
	// created already with the default AMI
	blockDeviceMapping := ec2.BlockDeviceMapping{
		DeviceName:          device.DeviceName,
		VirtualName:         device.VirtualName,
		SnapshotId:          device.SnapshotId,
		VolumeType:          "standard", // Use magnetic storage because it is cheaper
		VolumeSize:          int64(storageSize),
		DeleteOnTermination: true,
		Encrypted:           false,
	}

	p.Log.Debug("Using subnet: '%s', zone: '%s', sg: '%s'. Subnet has %d available IPs",
		subnet.SubnetId, subnet.AvailabilityZone, group.Id, subnet.AvailableIpAddressCount)

	if a.Builder.InstanceType == "" {
		p.Log.Critical("Instance type is empty. This shouldn't happen. Fallback to t2.micro")
		a.Builder.InstanceType = T2Micro.String()
	}

	kiteUUID, err := uuid.NewV4()
	if err != nil {
		return nil, err
	}

	kiteId := kiteUUID.String()

	userData, err := p.userData(m, kiteId)
	if err != nil {
		return nil, err
	}

	ec2Data := &ec2.RunInstances{
		ImageId:                  image.Id,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  p.KeyName,
		InstanceType:             a.Builder.InstanceType,
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

func (p *Provider) userData(m *protocol.Machine, kiteId string) ([]byte, error) {
	errLog := p.GetCustomLogger(m.Id, "error")

	kiteKey, err := p.createKey(m.Username, kiteId)
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

	return userdata.Bytes(), nil

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
