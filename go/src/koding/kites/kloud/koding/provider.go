package koding

import (
	"errors"
	"fmt"
	"time"

	"koding/db/mongodb"
	"koding/kites/kloud/klient"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	amazonClient "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/kloud/waitstate"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

var (
	DefaultCustomAMITag = "koding-stable" // Only use AMI's that have this tag
	DefaultInstanceType = "t2.micro"
	DefaultRegion       = "us-east-1"

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	kodingCredential = map[string]interface{}{
		"access_key": "AKIAIDPT7E2UHZHT2CXQ",
		"secret_key": "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",
	}
)

const (
	ProviderName      = "koding"
	DefaultApachePort = 80
	DefaultKitePort   = 3000
)

// Provider implements the kloud packages Storage, Builder and Controller
// interface
type Provider struct {
	Kite         *kite.Kite
	Session      *mongodb.MongoDB
	AssigneeName string
	Log          logging.Logger
	Push         func(string, int, machinestate.State)

	// A flag saying if user permissions should be ignored
	// store negation so default value is aligned with most common use case
	Test bool

	// Contains the users home directory to be added into a image
	TemplateDir string

	// DNS is used to create/update domain recors
	DNS        *DNS
	HostedZone string

	Bucket *Bucket

	KontrolURL        string
	KontrolPrivateKey string
	KontrolPublicKey  string

	// If available a key pair with the given public key and name should be
	// deployed to the machine, the corresponding PrivateKey should be returned
	// in the ProviderArtifact. Some providers such as Amazon creates
	// publicKey's on the fly and generates the privateKey themself.
	PublicKey  string `structure:"publicKey"`
	PrivateKey string `structure:"privateKey"`
	KeyName    string `structure:"keyName"`
}

func (p *Provider) NewClient(machine *protocol.Machine) (*amazon.AmazonClient, error) {
	username := machine.Builder["username"].(string)

	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("[%s] %s (username: %s)", machine.MachineId, msg, username)

			machine.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error

	machine.Builder["region"] = DefaultRegion

	a.Amazon, err = amazonClient.New(kodingCredential, machine.Builder)
	if err != nil {
		return nil, fmt.Errorf("koding-amazon err: %s", err)
	}

	// needed to deploy during build
	a.Builder.KeyPair = p.KeyName

	// needed to create the keypair if it doesn't exist
	a.Builder.PublicKey = p.PublicKey
	a.Builder.PrivateKey = p.PrivateKey

	return a, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Resize(opts *protocol.Machine) (*protocol.Artifact, error) {
	/*
		1. Stop the instance
		2. Get VolumeId of current instance
		3. Get AvailabilityZone of current instance
		4. Create snapshot from that given VolumeId
		4a. Delete snapshot if something goes wrong in following steps // TODO
		5. Create new volume with the desired size from the snapshot and same availability zone.
		5a. Delete volume if something goes wrong in following steps // TODO
		6. Detach the volume of current stopped instance
		7. Attach new volume to current stopped instance
		8. Start the stopped instance
		9. Check if new volume partition needs resizing, run "resize2fs" inside machine if needed via SSH
		10. Delete old volume
		11. Delete old snapshot
		11. Update Domain record with the new IP
		12. Check if Klient is running
		13. Return success
	*/

	defer p.Unlock(opts.MachineId)

	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	// 1. Stop the instance
	a.Log.Info("1. Stopping Machine")
	if opts.State != machinestate.Stopped {
		err = a.Stop()
		if err != nil {
			return nil, err
		}
	}

	p.UpdateState(opts.MachineId, machinestate.Pending)

	// 2. Get VolumeId of current instance
	a.Log.Info("2. Getting Volume Id")
	instance, err := a.Instance(a.Id())
	if err != nil {
		return nil, err
	}

	oldVolumeId := instance.BlockDevices[0].VolumeId

	// 3. Get AvailabilityZone of current instance
	a.Log.Info("3. Getting Avail Zone")
	availZone := instance.AvailZone

	// 4. Create snapshot from that given VolumeId
	a.Log.Info("4. Create snapshot from volume %s", oldVolumeId)
	snapshotDesc := fmt.Sprintf("Temporary snapshot for instance %s", instance.InstanceId)
	resp, err := a.Client.CreateSnapshot(oldVolumeId, snapshotDesc)
	if err != nil {
		return nil, err
	}

	newSnapshotId := resp.Id

	checkSnapshot := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Snapshots([]string{newSnapshotId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		if resp.Snapshots[0].Status != "completed" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws := waitstate.WaitState{StateFunc: checkSnapshot, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	// 5. Create new volume with the desired size from the snapshot and same availability zone.
	a.Log.Info("5. Create new volume from snapshot %s", newSnapshotId)
	volOptions := &ec2.CreateVolume{
		AvailZone:  availZone,
		Size:       15, // TODO: Change it after you are done!
		SnapshotId: newSnapshotId,
		VolumeType: "gp2", // SSD
	}

	volResp, err := a.Client.CreateVolume(volOptions)
	if err != nil {
		return nil, err
	}

	newVolumeId := volResp.VolumeId

	checkVolume := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{newVolumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		if resp.Volumes[0].Status != "available" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws = waitstate.WaitState{StateFunc: checkVolume, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	// 6. Detach the volume of current stopped instance
	a.Log.Info("6. Detach old volume %s", oldVolumeId)
	if _, err := a.Client.DetachVolume(oldVolumeId); err != nil {
		return nil, err
	}

	checkDetaching := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{oldVolumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}
		vol := resp.Volumes[0]

		// ready!
		if len(vol.Attachments) == 0 {
			return machinestate.Stopped, nil
		}

		// otherwise wait until it's detached
		if vol.Attachments[0].Status != "detached" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws = waitstate.WaitState{StateFunc: checkDetaching, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	// 7. Attach new volume to current stopped instance
	a.Log.Info("7. Attach new volume %s", newVolumeId)
	if _, err := a.Client.AttachVolume(newVolumeId, a.Id(), "/dev/sda1"); err != nil {
		return nil, err
	}

	checkAttaching := func(currentPercentage int) (machinestate.State, error) {
		resp, err := a.Client.Volumes([]string{newVolumeId}, ec2.NewFilter())
		if err != nil {
			return 0, err
		}

		vol := resp.Volumes[0]

		if len(vol.Attachments) == 0 {
			return machinestate.Pending, nil
		}

		if vol.Attachments[0].Status != "attached" {
			return machinestate.Pending, nil
		}

		return machinestate.Stopped, nil
	}

	ws = waitstate.WaitState{StateFunc: checkAttaching, DesiredState: machinestate.Stopped}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return nil, errors.New("resize it not supported")
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	artifact, err := a.Start()
	if err != nil {
		return nil, err
	}

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Starting)

	/////// ROUTE 53 /////////////////
	if err := p.InitDNS(opts); err != nil {
		return nil, err
	}

	username := opts.Builder["username"].(string)

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return nil, err
	}

	a.Push("Checking domain", 70, machinestate.Starting)
	// Check if the record exist, if yes update the ip instead of creating a new one.
	record, err := p.DNS.Domain(machineData.Domain)
	if err == ErrNoRecord {
		a.Push("Creating domain", 75, machinestate.Starting)
		if err := p.DNS.CreateDomain(machineData.Domain, artifact.IpAddress); err != nil {
			return nil, err
		}
	} else if err != nil {
		// If it's something else just return it
		return nil, err
	}

	// Means the record exist, update it
	if err == nil {
		a.Push("Updating domain", 75, machinestate.Starting)
		p.Log.Warning("[%s] Domain '%s' already exists (that shouldn't happen). Going to update to new IP",
			opts.MachineId, machineData.Domain)
		if err := p.DNS.Update(machineData.Domain, record.Records[0], artifact.IpAddress); err != nil {
			return nil, err
		}
	}

	a.Log.Info("[%s] Updating user domain tag '%s' of instance '%s'",
		opts.MachineId, machineData.Domain, artifact.InstanceId)

	a.Push("Adding domain tag", 80, machinestate.Starting)
	if err := a.AddTag(artifact.InstanceId, "koding-domain", machineData.Domain); err != nil {
		return nil, err
	}

	artifact.DomainName = machineData.Domain

	///// ROUTE 53 /////////////////

	a.Push("Checking remote machine", 90, machinestate.Starting)
	p.Log.Info("[%s] Connecting to remote Klient instance", opts.MachineId)
	klientRef, err := klient.NewWithTimeout(p.Kite, machineData.QueryString, time.Minute*1)
	if err != nil {
		p.Log.Warning("Connecting to remote Klient instance err: %s", err)
	} else {
		defer klientRef.Close()
		p.Log.Info("[%s] Sending a ping message", opts.MachineId)
		if err := klientRef.Ping(); err != nil {
			p.Log.Warning("Sending a ping message err:", err)
		}
	}

	return artifact, nil
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Stop()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////
	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Stopping)
	if err := p.InitDNS(opts); err != nil {
		return err
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Deleting domain", 75, machinestate.Stopping)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////

	a.Push("Updating ip address", 85, machinestate.Stopping)
	if err := p.Update(opts.MachineId, &kloud.StorageData{
		Type: "stop",
		Data: map[string]interface{}{
			"ipAddress": "",
		},
	}); err != nil {
		p.Log.Error("[stop] storage update of essential data was not possible: %s", err.Error())
	}

	return nil
}

func (p *Provider) Restart(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Destroy()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////

	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	if err := p.InitDNS(opts); err != nil {
		return err
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Checking domain", 75, machinestate.Terminating)
	// Check if the record exist, it can be deleted via stop, therefore just
	// return lazily
	_, err = p.DNS.Domain(machineData.Domain)
	if err == ErrNoRecord {
		return nil
	}

	// If it's something else just return it
	if err != nil {
		return err
	}

	a.Push("Deleting domain", 85, machinestate.Terminating)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////
	return nil
}
