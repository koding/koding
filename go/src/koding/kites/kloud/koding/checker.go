package koding

import (
	"fmt"
	"koding/db/mongodb"
	"strconv"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	aws "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

// Checker checks various aspects of a machine. It is used for limiting certain
// aspects of a machine, such as the total allowed machine count, storage size
// and etc.
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
	Plan     Plan
}

func (p *PlanChecker) AllowedInstances(wantInstance InstanceType) error {
	allowedInstances := p.Plan.Limits().AllowedInstances

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (p *PlanChecker) AlwaysOn() error {
	alwaysOnLimit := p.Plan.Limits().AlwaysOn

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

	p.Log.Debug("[%s] checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, alwaysOnMachines, alwaysOnLimit, p.Plan)

	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		p.Log.Debug("[%s] allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, alwaysOnMachines, alwaysOnLimit, p.Plan)
		return nil // allow user, it didn't reach the limit
	}

	p.Log.Debug("[%s] denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, p.Username, alwaysOnMachines, alwaysOnLimit, p.Plan)
	return fmt.Errorf("total alwaysOn limit has been reached. Current count: %d Plan limit: %d",
		alwaysOnMachines, alwaysOnLimit)
}

func (p *PlanChecker) Timeout() error {
	// Check klient state before rushing to AWS.
	klientRef, err := klient.Connect(p.Kite, p.Machine.QueryString)
	if err == kite.ErrNoKitesAvailable {
		p.Provider.startTimer(p.Machine)
		return err
	}

	// return if it's something else
	if err != nil {
		return err
	}

	// now the klient is connected and we can ping it, stop the timer and
	// remove it from the list of inactive machines if it's still there.
	p.Provider.stopTimer(p.Machine)

	// replace with the real and authenticated username
	p.Machine.Builder["username"] = klientRef.Username
	p.Username = klientRef.Username

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klientRef.Usage()

	klientRef.Close()
	klientRef = nil

	if err != nil {
		return err
	}

	// get the timeout from the plan in which the user belongs to
	planTimeout := p.Plan.Limits().Timeout

	p.Log.Debug("[%s] machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		p.Machine.Id, p.Machine.IpAddress, usg.InactiveDuration, planTimeout, p.Plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.Log.Info("[%s] machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		p.Machine.Id, p.Machine.IpAddress, usg.InactiveDuration, p.Plan)

	// lock so it doesn't interfere with others.
	p.Provider.Lock(p.Machine.Id)

	// mark our state as stopping so others know what we are doing
	stoppingReason := fmt.Sprintf("Stopping process started due inactivity of %.f minutes",
		planTimeout.Minutes())
	p.Provider.UpdateState(p.Machine.Id, stoppingReason, machinestate.Stopping)

	defer func() {
		// call it in defer, so even if "Stop" fails it should reset the state
		stopReason := fmt.Sprintf("Stopped due inactivity of %.f minutes", planTimeout.Minutes())
		p.Provider.UpdateState(p.Machine.Id, stopReason, machinestate.Stopped)

		p.Provider.Unlock(p.Machine.Id)
	}()

	// Hasta la vista, baby!
	return p.Provider.Stop(p.Machine)
}

func (p *PlanChecker) Total() error {
	allowedMachines := p.Plan.Limits().Total

	instances, err := p.userInstances()

	// no match, allow to create instance
	if err == aws.ErrNoInstances {
		p.Log.Debug("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, len(instances), allowedMachines, p.Plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	go p.checkGhostMachines(instances)

	if len(instances) >= allowedMachines {
		p.Log.Debug("[%s] denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Machine.Id, p.Username, len(instances), allowedMachines, p.Plan)
		return fmt.Errorf("total machine limit has been reached. Current count: %d Plan limit: ",
			len(instances), allowedMachines)
	}

	p.Log.Debug("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		p.Machine.Id, p.Username, len(instances), allowedMachines, p.Plan)

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
	totalStorage := p.Plan.Limits().Storage

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

	p.Log.Debug("[%s] Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.Machine.Id, currentStorage, wantStorage, totalStorage, p.Plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can use %dGB of %dGB (plan: %s)",
			totalStorage-currentStorage, totalStorage, p.Plan)
	}

	p.Log.Debug("[%s] Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.Machine.Id, p.Username, currentStorage, wantStorage, totalStorage, p.Plan)

	// allow to create storage
	return nil
}

func (p *PlanChecker) userInstances() ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-value", p.Username)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := p.Api.InstancesByFilter(filter)
	if err != nil {
		return nil, err
	}

	filtered := []ec2.Instance{}

	// we don't use filters because they are timing out for us due to high
	// instances count we have. However it seems the filter `tag-value` has an
	// index internally inside AWS so somewhot that one is not timing out.
	for _, instance := range instances {
		for _, tag := range instance.Tags {
			if tag.Key == "koding-user" && tag.Value == p.Username {
				for _, tag := range instance.Tags {
					if tag.Key == "koding-env" && tag.Value == p.Kite.Config.Environment {

						// now we have the instance that matches both the correct username
						// and environment
						filtered = append(filtered, instance)
					}
				}
			}
		}
	}

	// garbage collect it
	instances = nil
	return filtered, nil
}
