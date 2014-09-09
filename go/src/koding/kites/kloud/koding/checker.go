package koding

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/klient"
	"strconv"

	"github.com/koding/kite"
	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

type PlanChecker struct {
	api      *amazon.AmazonClient
	db       *mongodb.MongoDB
	machine  *protocol.Machine
	provider *Provider
	kite     *kite.Kite
	username string
	log      logging.Logger
}

// PlanChecker creates and returns a new PlanChecker struct that is responsible
// of checking various pieces of informations based on a Plan
func (p *Provider) PlanChecker(opts *protocol.Machine) (*PlanChecker, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	ctx := &PlanChecker{
		api:      a,
		provider: p,
		db:       p.Session,
		kite:     p.Kite,
		username: opts.Builder["username"].(string),
		log:      p.Log,
		machine:  opts,
	}

	return ctx, nil
}

// Plan returns user's current plan
func (p *PlanChecker) Plan() (Plan, error) {
	return Free, nil
}

// Timeout checks whether the user has reached the current plan's inactivity timeout.
func (p *PlanChecker) Timeout() error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	// get the timeout from the plan in which the user belongs to
	planTimeout := plan.Limits().Timeout

	machineData, ok := p.machine.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", p.machine.CurrentData)
	}

	// connect and get real time data directly from the machines klient
	klient, err := klient.New(p.kite, machineData.QueryString)
	if err != nil {
		return err
	}
	defer klient.Close()

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klient.Usage()
	if err != nil {
		return err
	}

	p.log.Info("[%s] machine [%s] is inactive for %s (current plan limit: %s).",
		machineData.Id.Hex(), machineData.IpAddress, usg.InactiveDuration, planTimeout)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.log.Info("[%s] machine [%s] has reached current plan limit of %s. Shutting down...",
		machineData.Id.Hex(), machineData.IpAddress, usg.InactiveDuration, planTimeout)

	// mark our state as stopping so others know what we are doing
	p.provider.UpdateState(machineData.Id.Hex(), machinestate.Stopping)

	// replace with the real and authenticated username
	p.machine.Builder["username"] = klient.Username

	// Hasta la vista, baby!
	err = p.provider.Stop(p.machine)
	if err != nil {
		return err
	}

	// update to final state too
	return p.provider.UpdateState(machineData.Id.Hex(), machinestate.Stopped)
}

// Total checks whether the user has reached the current plan's limit of having
// a total number numbers of machines. It returns an error if the limit is
// reached or an unexplained error happaned.
func (p *PlanChecker) Total() error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	allowedMachines := plan.Limits().Total

	instances, err := p.userInstances()

	// no match, allow to create instance
	if err == aws.ErrNoInstances {
		p.log.Info("[%s] allowing user '%s'. Current machine count: %d, Total machine limit: %d",
			p.machine.MachineId, p.username, len(instances), allowedMachines)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		p.log.Info("[%s] denying user '%s'. Current machine count: %d, Total machine limit: %d",
			p.machine.MachineId, p.username, len(instances), allowedMachines)

		return fmt.Errorf("total limit of %d machines has been reached", allowedMachines)
	}

	p.log.Info("[%s] allowing user '%s'. Current machine count: %d, Total machine limit: %d",
		p.machine.MachineId, p.username, len(instances), allowedMachines)

	return nil
}

// Storage checks whether the user has reached the current plan's limit total
// storage with the supplied wantStorage information. It returns an error if
// the limit is reached or an unexplained error happaned.
func (p *PlanChecker) Storage(wantStorage int) error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	totalStorage := plan.Limits().Storage

	instances, err := p.userInstances()

	// i hate for loops too, but unfortunaly the responses are always in form
	// of slices
	currentStorage := 0
	for _, instance := range instances {
		for _, blockDevice := range instance.BlockDevices {
			volumes, err := p.api.Client.Volumes([]string{blockDevice.VolumeId}, ec2.NewFilter())
			if err != nil {
				return err
			}

			for _, volume := range volumes.Volumes {
				volumeStorage, err := strconv.Atoi(volume.Size)
				if err != nil {
					return err
				}

				currentStorage += volumeStorage
			}
		}
	}

	p.log.Info("[%s] Checking storage. Current storage: %dGB. Want storage: %dGB. Total storage limit: %dGB",
		p.machine.MachineId, currentStorage, wantStorage, totalStorage)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can use %dGB of %dGB", totalStorage-currentStorage, totalStorage)
		// return fmt.Errorf("total storage limit of %d GB has been reached", totalStorage)
	}

	p.log.Info("[%s] Allowing user '%s'. Current storage: %dGB. Want storage: %dGB. Total storage limit: %dGB",
		p.machine.MachineId, p.username, currentStorage, wantStorage, totalStorage)

	// allow to create storage
	return nil
}

func (p *PlanChecker) userInstances() ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	// instances in Amazon have a `koding-user` tag with the username as the
	// value. We can easily find them acording to this tag
	filter.Add("tag:koding-user", p.username)
	filter.Add("tag:koding-env", p.kite.Config.Environment)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	return p.api.InstancesByFilter(filter)

}
