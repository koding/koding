package koding

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/klient"
	"strconv"
	"strings"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/kite"
	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
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
	api      *amazon.AmazonClient
	db       *mongodb.MongoDB
	machine  *protocol.Machine
	provider *Provider
	kite     *kite.Kite
	username string
	log      logging.Logger
}

// PlanChecker creates and returns a new Checker interface that is responsible
// of checking various pieces of informations based on a Plan
func (p *Provider) PlanChecker(opts *protocol.Machine) (Checker, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	checker := &PlanChecker{
		api:      a,
		provider: p,
		db:       p.Session,
		kite:     p.Kite,
		username: opts.Builder["username"].(string),
		log:      p.Log,
		machine:  opts,
	}

	return checker, nil
}

// Plan returns user's current plan
func (p *PlanChecker) Plan() (Plan, error) {
	var account = struct {
		GlobalFlags []string `bson:"globalFlags"`
	}{}
	if err := p.db.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": p.username}).One(&account)
	}); err != nil {
		p.log.Warning("[%s] retrieving plan failed, mongodb lookup err: %s. Using free plan",
			p.machine.MachineId, err.Error())
		return Free, nil
	}

	if len(account.GlobalFlags) == 0 {
		p.log.Warning("[%s] retrieving plan failed, no flag defined. Using free plan",
			p.machine.MachineId)
		return Free, nil
	}

	// pick up the first flag that start with "plan-"
	planFlag := ""
	for _, flag := range account.GlobalFlags {
		if strings.HasPrefix(flag, "plan-") {
			planFlag = flag
			break
		}
	}

	splitted := strings.Split(planFlag, "-")
	if len(splitted) != 2 {
		p.log.Warning("[%s] retrieving plan failed, flag '%v' malformed. Using free plan",
			p.machine.MachineId, planFlag)
		return Free, nil
	}

	plan, ok := plans[strings.Title(splitted[1])]
	if !ok {
		p.log.Warning("[%s] retrieving plan failed, flag plan '%v' does not exist. Using free plan",
			p.machine.MachineId, splitted[1])
		return Free, nil
	}

	return plan, nil
}

func (p *PlanChecker) AllowedInstances(wantInstance InstanceType) error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	allowedInstances := plan.Limits().AllowedInstances

	p.log.Info("[%s] checking instance type. want: %s (plan: %s)",
		p.machine.MachineId, wantInstance, plan)

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (p *PlanChecker) AlwaysOn() error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	machineData, ok := p.machine.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", p.machine.CurrentData)
	}

	alwaysOnLimit := plan.Limits().AlwaysOn

	user := machineData.Users[0]

	// get all alwaysOn machines that belongs to this user
	alwaysOnMachines := 0
	err = p.db.Run("jMachines", func(c *mgo.Collection) error {
		alwaysOnMachines, err = c.Find(bson.M{
			"users.id":      user.Id,
			"meta.alwaysOn": true,
		}).Count()

		return err
	})

	// if it's something else just return an error, needs to be fixed
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	p.log.Info("[%s] checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.machine.MachineId, alwaysOnMachines, alwaysOnLimit, plan)
	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		p.log.Info("[%s] allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			p.machine.MachineId, p.username, alwaysOnMachines, alwaysOnLimit, plan)
		return nil
	}

	p.log.Info("[%s] denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.machine.MachineId, p.username, alwaysOnMachines, alwaysOnLimit, plan)
	return fmt.Errorf("total alwaysOn limit has been reached")
}

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

	p.log.Info("[%s] machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		machineData.Id.Hex(), machineData.IpAddress, usg.InactiveDuration, planTimeout, plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.log.Info("[%s] machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		machineData.Id.Hex(), machineData.IpAddress, usg.InactiveDuration, planTimeout, plan)

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

func (p *PlanChecker) Total() error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	allowedMachines := plan.Limits().Total

	instances, err := p.userInstances()

	// no match, allow to create instance
	if err == aws.ErrNoInstances {
		p.log.Info("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.machine.MachineId, p.username, len(instances), allowedMachines, plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		p.log.Info("[%s] denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.machine.MachineId, p.username, len(instances), allowedMachines, plan)

		return fmt.Errorf("total limit of %d machines has been reached", allowedMachines)
	}

	p.log.Info("[%s] allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		p.machine.MachineId, p.username, len(instances), allowedMachines, plan)

	return nil
}

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

	p.log.Info("[%s] Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.machine.MachineId, currentStorage, wantStorage, totalStorage, plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can use %dGB of %dGB (plan: %s)",
			totalStorage-currentStorage, totalStorage, plan)
	}

	p.log.Info("[%s] Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.machine.MachineId, p.username, currentStorage, wantStorage, totalStorage, plan)

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
