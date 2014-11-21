package koding

import (
	"errors"
	"fmt"
	"strconv"
	"time"

	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/mitchellh/goamz/ec2"
)

// Starting from cheapest, list is according to us-east and coming from:
// http://www.ec2instances.info/. t2.micro is not included because it's
// already the default type which we start to build. Only supported types
// are here.
var InstancesList = []string{
	"t2.small",
	"t2.medium",
	"m3.medium",
	"c3.large",
	"m3.large",
	"c3.xlarge",
}

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

	a.Push("Checking initial data", normalize(10), machinestate.Building)

	a.Push("Generating and fetching build data", normalize(20), machinestate.Building)
	buildData, err := p.buildData(a, m)
	if err != nil {
		errLog("Get build data err: %v", err)
		return nil, err
	}

	if err := p.checkFunc(m, buildData); err != nil {
		return nil, err
	}

	buildArtifact, err := p.buildFunc(a, m, buildData)
	if err != nil {
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

	afterBuildFunc := func() error {
		// this can happen when an Info method is called on a terminated instance.
		// This updates the DB records with the name that EC2 gives us, which is a
		// "terminated-instance"
		instanceName := m.Builder["instanceName"].(string)
		if instanceName == "terminated-instance" {
			instanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
			debugLog("Instance name is an artifact (terminated), changing to %s", instanceName)
		}

		a.Push("Updating/Creating domain", normalize(70), machinestate.Building)
		if err := p.UpdateDomain(buildArtifact.IpAddress, m.Domain.Name, m.Username); err != nil {
			return err
		}

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

		buildArtifact.InstanceName = instanceName
		buildArtifact.MachineId = m.Id
		buildArtifact.DomainName = m.Domain.Name

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
		}

		return nil
	}

	checkKiteFunc := func() error {
		query := kiteprotocol.Kite{ID: buildData.KiteId}
		buildArtifact.KiteQuery = query.String()

		a.Push("Checking connectivity", normalize(75), machinestate.Building)

		debugLog("Connecting to remote Klient instance")
		if p.IsKlientReady(query.String()) {
			debugLog("klient is ready.", m.Id)
		} else {
			p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
		}

		return nil
	}

	steps := []func() error{
		afterBuildFunc,
		checkKiteFunc,
	}

	for i, fn := range steps {
		fmt.Printf("Building step %d \n", i)
		if err := fn(); err != nil {
			return nil, err
		}
	}

	return buildArtifact, nil
}

func (p *Provider) buildFunc(a *amazon.AmazonClient, m *protocol.Machine, buildData *BuildData) (*protocol.Artifact, error) {
	// build our instance in a normal way
	buildArtifact, err := a.Build(buildData.EC2Data, normalize(45), normalize(60))
	if err == nil {
		return buildArtifact, nil
	}

	// check if the error is a 'InsufficientInstanceCapacity" error or
	// "InstanceLimitExceeded, if not return back because it's not a
	// resource or capacity problem.
	if !isCapacityError(err) {
		return nil, err
	}

	p.Log.Error("[%s] IMPORTANT: %s", m.Id, err)

	// now lets to some fallback mechanisms to avoid the capacity errors.
	// 1. Try to use a different zone
	zoneFunc := func() (*protocol.Artifact, error) {
		zones, err := p.EC2Clients.Zones(a.Client.Region.Name)
		if err != nil {
			return nil, fmt.Errorf("couldn't fetch availability zones: %s", err)

		}

		p.Log.Debug("[%s] Fallback: Searching for a zone that has capacity amongst zones: %v", m.Id, zones)
		for _, zone := range zones {
			if zone == buildData.EC2Data.AvailZone {
				// skip it because that's one is causing problems and doesn't have any capacity
				continue
			}

			subnets, err := a.SubnetsWithTag(DefaultKloudKeyName)
			if err != nil {
				return nil, err
			}

			subnet, err := subnets.AvailabilityZone(zone)
			if err != nil {
				continue // shouldn't be happen, but let be safe
			}

			group, err := a.SecurityGroupFromVPC(subnet.VpcId, DefaultKloudKeyName)
			if err != nil {
				return nil, err
			}

			// add now our security group
			buildData.EC2Data.SecurityGroups = []ec2.SecurityGroup{{Id: group.Id}}
			buildData.EC2Data.AvailZone = zone
			buildData.EC2Data.SubnetId = subnet.SubnetId

			p.Log.Warning("[%s] Building again by using availability zone: %s and subnet %s.",
				m.Id, zone, subnet.SubnetId)

			buildArtifact, err := a.Build(buildData.EC2Data, normalize(60), normalize(70))
			if err == nil {
				return buildArtifact, nil
			}

			if isCapacityError(err) {
				// if there is no capacity we are going to use the next one
				p.Log.Warning("[%s] Build failed on availability zone '%s' due to AWS capacity problems. Trying another region.",
					m.Id, zone)
				continue
			}

			return nil, err
		}

		return nil, errors.New("no other zones are available")
	}

	// 2. Try to use another instance
	// TODO: do not choose an instance lower than the current user
	// instance. Currently all we give is t2.micro, however it if the user
	// has a t2.medium, we'll give them a t2.small if there is no capacity,
	// which needs to be fixed in the near future.
	instanceFunc := func() (*protocol.Artifact, error) {
		for _, instanceType := range InstancesList {
			p.Log.Warning("[%s] Fallback: building again with using instance: %s instead of %s.",
				m.Id, instanceType, buildData.EC2Data.InstanceType)

			buildData.EC2Data.InstanceType = instanceType

			buildArtifact, err := a.Build(buildData.EC2Data, normalize(60), normalize(70))
			if err == nil {
				return buildArtifact, nil // we are finished!
			}

			p.Log.Warning("[%s] Fallback: couldn't build instance with type: '%s'. err: %s ",
				m.Id, instanceType, err)
		}

		return nil, errors.New("no other instances are available")
	}

	// We are going to to try each step and for each step if we get
	// "InsufficentInstanceCapacity" error we move to the next one.
	for _, fn := range []func() (*protocol.Artifact, error){zoneFunc, instanceFunc} {
		buildArtifact, err := fn()
		if err != nil {
			p.Log.Error("Build failed. Moving to next fallback step: %s", err)
			continue // pick up the next function
		}

		return buildArtifact, nil
	}

	return nil, errors.New("build reached the end. all fallback mechanism steps failed.")
}

func (p *Provider) checkFunc(m *protocol.Machine, buildData *BuildData) error {
	errLog := p.GetCustomLogger(m.Id, "error")

	// Check for total machine allowance
	checker, err := p.PlanChecker(m)
	if err != nil {
		return err
	}

	if err := checker.Total(); err != nil {
		errLog("Checking total machine err: %s", err)
		return err
	}

	if err := checker.AlwaysOn(); err != nil {
		errLog("Checking always on limit err: %s", err)
		return err
	}

	p.Log.Debug("[%s] Check if user is allowed to create instance type %s",
		m.Id, buildData.EC2Data.InstanceType)

	// check if the user is egligible to create a vm with this instance type
	if err := checker.AllowedInstances(instances[buildData.EC2Data.InstanceType]); err != nil {
		p.Log.Critical("[%s] Instance type (%s) is not allowed. This shouldn't happen. Fallback to t2.micro",
			m.Id, buildData.EC2Data.InstanceType)
		buildData.EC2Data.InstanceType = T2Micro.String()
	}

	// check if the user is egligible to create a vm with this size
	if err := checker.Storage(int(buildData.EC2Data.BlockDevices[0].VolumeSize)); err != nil {
		errLog("Checking storage size failed err: %v", err)
		return err
	}

	return nil
}
