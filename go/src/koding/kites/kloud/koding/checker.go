package koding

import (
	"fmt"
	"koding/db/mongodb"
	"strconv"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	aws "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

// Checker checks various aspects of a machine. It used to limit certain
// aspects of a machine, such a the total machine or total storage.
type Checker interface {
	// Total checks whether the user has reached the current plan's limit of
	// having a total number numbers of machines. It returns an error if the
	// limit is reached or an unexplained error happaned.
	Total() error

	// AlwaysOn checks whether the given machine has reached the current plans
	// always on limit
	AlwaysOn() error

	// Timeout checks whether the user has reached the current plan's
	// inactivity timeout.
	Timeout() error

	// Storage checks whether the user has reached the current plan's limit
	// total storage with the supplied wantStorage information. It returns an
	// error if the limit is reached or an unexplained error happaned.
	Storage(wantStorage int) error

	// AllowedInstances checks whether the given machine has the permisison to
	// create the given instance type
	AllowedInstances(wantInstance InstanceType) error
}

type PlanChecker struct {
	Api      *amazon.AmazonClient
	DB       *mongodb.MongoDB
	Machine  *protocol.Machine
	Provider *Provider
	Kite     *kite.Kite
	Username string
	Log      logging.Logger
}

func (p *PlanChecker) AllowedInstances(wantInstance InstanceType) error {
	plan, err := p.Provider.PlanFetcher(p.Machine)
	if err != nil {
		return err
	}

	allowedInstances := plan.Limits().AllowedInstances

	p.Log.Info("[%s] checking instance type. want: %s (plan: %s)",
		p.Machine.Id, wantInstance, plan)

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (p *PlanChecker) AlwaysOn() error {
	plan, err := p.Provider.PlanFetcher(p.Machine)
	if err != nil {
		return err
	}

	alwaysOnLimit := plan.Limits().AlwaysOn

	// get all alwaysOn machines that belongs to this user
	alwaysOnMachines := 0
	if err := p.DB.Run("jMachines", func(c *mgo.Collection) error {
		var err error
		alwaysOnMachines, err = c.Find(bson.M{
			"credential":    p.Machine.Username,
			"meta.alwaysOn": true,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	p.Log.Info("[%s] checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, alwaysOnMachines, alwaysOnLimit, plan)
	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		p.Log.Info("[%s] allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, alwaysOnMachines, alwaysOnLimit, plan)
		return nil
	}

	p.Log.Info("[%s] denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, p.Username, alwaysOnMachines, alwaysOnLimit, plan)
	return fmt.Errorf("total alwaysOn limit has been reached")
}

func (p *PlanChecker) Timeout() error {
	// capture it into a closure so we can use it twice
	stopMachine := func() error {
		// lock so it doesn't interfere with others.
		p.Provider.Lock(p.Machine.Id)
		defer p.Provider.Unlock(p.Machine.Id)

		// mark our state as stopping so others know what we are doing
		p.Provider.UpdateState(p.Machine.Id, machinestate.Stopping)

		// Hasta la vista, baby!
		err := p.Provider.Stop(p.Machine)
		if err != nil {
			return err
		}

		// update to final state too
		return p.Provider.UpdateState(p.Machine.Id, machinestate.Stopped)
	}

	// connect and get real time data directly from the machines klient
	klient, err := p.Provider.KlientPool.Get(p.Machine.QueryString)
	if err == kite.ErrNoKitesAvailable {
		p.Provider.InactiveMachinesMu.Lock()
		_, ok := p.Provider.InactiveMachines[p.Machine.QueryString]
		p.Provider.InactiveMachinesMu.Unlock()
		if ok {
			// no need to return an error, because it's already in the map so
			// it will be expired with the function below
			return nil
		}

		p.Log.Info("[%s] klient is not running, adding machine to list of inactive machines.", p.Machine.Id)
		p.Provider.InactiveMachines[p.Machine.QueryString] = time.AfterFunc(time.Minute*5, func() {
			p.Log.Info("[%s] stopping machine after five minutes klient disconnection.", p.Machine.Id)
			if err := stopMachine(); err != nil {
				p.Log.Warning("[%s] could not stop ghost machine %s", p.Machine.Id, err)
			}

			// we don't need it anymore
			p.Provider.InactiveMachinesMu.Lock()
			delete(p.Provider.InactiveMachines, p.Machine.QueryString)
			p.Provider.InactiveMachinesMu.Unlock()
		})

		return err
	}

	// return if it's something else
	if err != nil {
		return err
	}

	// now the klient is connected again, stop the timer and remove it from the
	// list of inactive machines if it's still there.
	p.Provider.InactiveMachinesMu.Lock()
	if timer, ok := p.Provider.InactiveMachines[p.Machine.QueryString]; ok {
		timer.Stop()
		p.Provider.InactiveMachines[p.Machine.QueryString] = nil // garbage collect
		delete(p.Provider.InactiveMachines, p.Machine.QueryString)
	}
	p.Provider.InactiveMachinesMu.Unlock()

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klient.Usage()
	if err != nil {
		return err
	}

	plan, err := p.Provider.PlanFetcher(p.Machine)
	if err != nil {
		return err
	}

	// replace with the real and authenticated username
	p.Machine.Builder["username"] = klient.Username
	p.Username = klient.Username

	// get the timeout from the plan in which the user belongs to
	planTimeout := plan.Limits().Timeout

	p.Log.Debug("[%s] machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		p.Machine.Id, p.Machine.IpAddress, usg.InactiveDuration, planTimeout, plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.Log.Info("[%s] machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		p.Machine.Id, p.Machine.IpAddress, usg.InactiveDuration, planTimeout, plan)

	return stopMachine()
}

func (p *PlanChecker) Total() error {
	plan, err := p.Provider.PlanFetcher(p.Machine)
	if err != nil {
		return err
	}

	allowedMachines := plan.Limits().Total

	instances, err := p.userInstances()

	// no match, allow to create instance
	if err == aws.ErrNoInstances {
		p.Log.Info("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, len(instances), allowedMachines, plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	go p.checkGhostMachines(instances)

	if len(instances) >= allowedMachines {
		p.Log.Info("[%s] denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, len(instances), allowedMachines, plan)

		return fmt.Errorf("total limit of %d machines has been reached", allowedMachines)
	}

	p.Log.Info("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, p.Username, len(instances), allowedMachines, plan)

	return nil
}

func (p *PlanChecker) checkGhostMachines(instances []ec2.Instance) {
	for _, instance := range instances {
		for _, tag := range instance.Tags {
			if tag.Key != "koding-machineId" {
				continue
			}

			machineId := tag.Value

			// this is just for logging, so we don't care about handling
			// the error
			p.DB.Run("jMachines", func(c *mgo.Collection) error {
				n, err := c.FindId(bson.ObjectIdHex(machineId)).Count()
				if err != nil {
					return err
				}

				if n != 0 {
					return nil
				}

				p.Log.Warning("Detected a Ghost Machine in AWS! Instance id: %s", instance.InstanceId)
				return nil
			})
		}
	}
}

func (p *PlanChecker) Storage(wantStorage int) error {
	plan, err := p.Provider.PlanFetcher(p.Machine)
	if err != nil {
		return err
	}

	totalStorage := plan.Limits().Storage

	// no need for errors because instances will be empty in case of an error
	instances, _ := p.userInstances()

	// i hate for loops too, but unfortunaly the responses are always in form
	// of slices
	currentStorage := 0
	for _, instance := range instances {
		for _, blockDevice := range instance.BlockDevices {
			volumes, err := p.Api.Client.Volumes([]string{blockDevice.VolumeId}, ec2.NewFilter())
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

	p.Log.Info("[%s] Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.Machine.Id, currentStorage, wantStorage, totalStorage, plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can use %dGB of %dGB (plan: %s)",
			totalStorage-currentStorage, totalStorage, plan)
	}

	p.Log.Info("[%s] Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.Machine.Id, p.Username, currentStorage, wantStorage, totalStorage, plan)

	// allow to create storage
	return nil
}

func (p *PlanChecker) userInstances() ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	// instances in Amazon have a `koding-user` tag with the username as the
	// value. We can easily find them acording to this tag
	filter.Add("tag:koding-user", p.Username)
	filter.Add("tag:koding-env", p.Kite.Config.Environment)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	return p.Api.InstancesByFilter(filter)

}
