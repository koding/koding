package oldkoding

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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

	// SnapshotTotal checks whether the user reached the current plan's limit
	// of having a total numbers of snapshots. It returns an error if the limit
	// is reached or an unexplained error happened
	SnapshotTotal() error

	// Storage checks whether the user has reached the current plan's limit
	// total storage with the supplied wantStorage information. It returns an
	// error if the limit is reached or an unexplained error happaned.
	Storage(wantStorage int) error

	// AllowedInstances checks whether the given machine has the permisison to
	// create the given instance type
	AllowedInstances(wantInstance InstanceType) error

	// NetworkUsage checks whether the given machine has exceeded the network
	// outbound limit
	NetworkUsage() error

	// PlanState checks whether the given plan is valid or expired
	PlanState() error
}

type PlanChecker struct {
	Api      *amazon.Amazon
	DB       *mongodb.MongoDB
	Machine  *protocol.Machine
	Provider *Provider
	Kite     *kite.Kite
	Username string
	Log      logging.Logger
	Plan     *FetcherResponse
}

type networkUsageResponse struct {
	CanStart     bool    `json:"canStart"`
	Reason       string  `json:"reason"`
	AllowedUsage float64 `json:"allowedUsage"`
	CurrentUsage float64 `json:"currentUsage"`
}

func (p *PlanChecker) NetworkUsage() error {
	networkEndpoint, err := url.Parse(p.Provider.NetworkUsageEndpoint)
	if err != nil {
		p.Log.Debug("Failed to parse network-usage endpoint: %v. err: %v",
			p.Provider.NetworkUsageEndpoint, err)
		return err
	}

	var account *models.Account
	if err := p.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": p.Username}).One(&account)
	}); err != nil {
		p.Log.Warning("Failed to fetch user information while checking network-usage. err: %v",
			err)
		return err
	}

	// in case of error fetching network usage, assume it's ok to start
	var usageResponse = &networkUsageResponse{}
	usageResponse.CanStart = true

	q := networkEndpoint.Query()
	q.Set("account_id", account.Id.Hex())
	networkEndpoint.RawQuery = q.Encode()

	resp, err := http.Get(networkEndpoint.String())
	if err != nil {
		p.Log.Warning("Failed to fetch network-usage because network-usage providing api host seems down. err: %v",
			err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		p.Log.Debug("Network-usage response code is not 200. It's %v",
			resp.StatusCode)
		return nil
	}

	if err := json.NewDecoder(resp.Body).Decode(&usageResponse); err != nil {
		p.Log.Warning("Failed to decode network-usage response. err: %v",
			err)
		return nil
	}
	if !usageResponse.CanStart {
		p.Log.Debug("Network-usage limit is reached. Allowed usage: %v MiB, Current usage: %v MiB",
			usageResponse.AllowedUsage, usageResponse.CurrentUsage)

		err := fmt.Errorf("%s; allowed: %v, current: %v",
			usageResponse.Reason, usageResponse.AllowedUsage,
			usageResponse.CurrentUsage,
		)

		return err
	}
	return nil
}

func (p *PlanChecker) AllowedInstances(wantInstance InstanceType) error {
	allowedInstances := p.Plan.Plan.Limits().AllowedInstances

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (p *PlanChecker) AlwaysOn() error {
	alwaysOnLimit := p.Plan.Plan.Limits().AlwaysOn

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

	p.Log.Debug("checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		alwaysOnMachines, alwaysOnLimit, p.Plan.Plan)

	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		p.Log.Debug("allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			p.Username, alwaysOnMachines, alwaysOnLimit, p.Plan.Plan)
		return nil // allow user, it didn't reach the limit
	}

	p.Log.Info("denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		p.Username, alwaysOnMachines, alwaysOnLimit, p.Plan.Plan)
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
	planTimeout := p.Plan.Plan.Limits().Timeout

	p.Log.Debug("machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		p.Machine.IpAddress, usg.InactiveDuration, planTimeout, p.Plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.Log.Info("machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		p.Machine.IpAddress, usg.InactiveDuration, p.Plan)

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

func (p *PlanChecker) PlanState() error {
	// if the plan is expired there is no need to return the plan anymore
	if p.Plan.State != "" && strings.ToLower(p.Plan.State) == "expired" {
		return fmt.Errorf("[%s] Plan is expired", p.Machine.Id)
	}

	return nil
}

func (p *PlanChecker) Total() error {
	allowedMachines := p.Plan.Plan.Limits().Total

	instances, err := p.userInstances()

	// no match, allow to create instance
	if err == amazon.ErrNoInstances {
		p.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Username, len(instances), allowedMachines, p.Plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		p.Log.Debug("denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			p.Username, len(instances), allowedMachines, p.Plan)
		return fmt.Errorf("total machine limit has been reached. Current count: %d Plan limit: %d",
			len(instances), allowedMachines)
	}

	p.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		p.Username, len(instances), allowedMachines, p.Plan)

	return nil
}

func (p *PlanChecker) SnapshotTotal() error {
	allowedSnapshotCount := p.Plan.Plan.Limits().SnapshotTotal

	// lazy return
	if allowedSnapshotCount == 0 {
		p.Log.Debug("denying user to for snapshots, limit is zero already", p.Machine.Id)
		return fmt.Errorf("total snapshot limit has been reached. Plan limit: %d", allowedSnapshotCount)
	}

	currentSnapshotCount := 0
	if err := p.DB.Run("jSnapshots", func(c *mgo.Collection) error {
		var err error
		currentSnapshotCount, err = c.Find(bson.M{
			"machineId": bson.ObjectIdHex(p.Machine.Id),
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	p.Log.Debug("checking snapshot limit. current count: %d, plan limit: %d (plan: %s)",
		currentSnapshotCount, allowedSnapshotCount, p.Plan.Plan)

	// the user has still not reached the limit
	if currentSnapshotCount <= allowedSnapshotCount {
		p.Log.Debug("allowing user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
			p.Username, currentSnapshotCount, allowedSnapshotCount, p.Plan.Plan)
		return nil // allow user, it didn't reach the limit
	}

	p.Log.Info("denying user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
		p.Username, currentSnapshotCount, allowedSnapshotCount, p.Plan.Plan)
	return fmt.Errorf("total snapshot limit has been reached. Current count: %d Plan limit: %d",
		currentSnapshotCount, allowedSnapshotCount)

}

func (p *PlanChecker) Storage(wantStorage int) error {
	totalStorage := p.Plan.Plan.Limits().Storage

	// no need for errors because instances will be empty in case of an error
	instances, _ := p.userInstances()

	// we need to fetch JAccount here to get earnedRewards if exists
	var account *models.Account
	if err := p.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": p.Username}).One(&account)
	}); err != nil {
		p.Log.Warning("Failed to fetch user information while checking storage. err: %v",
			err)
		return err
	}

	rewardAmount := 0

	// querying the earnedReward of given account
	var reward *models.EarnedReward
	if err := p.DB.Run("jEarnedRewards", func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"originId": account.Id,
			"type":     "disk",
			"unit":     "MB",
		}).One(&reward)
	}); err != nil {
		// if there is a different error rather
		// than notFound we should stop here
		if err != mgo.ErrNotFound {
			return err
		}
	} else {
		// we got the amount as MB but aws only supports GB
		// dividing with 1000 not 1024.
		rewardAmount = reward.Amount / 1000
	}

	// and adding it to totalStorage
	// if there is no reward it will be 0 in this state
	totalStorage += rewardAmount

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

	p.Log.Debug("Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		currentStorage, wantStorage, totalStorage, p.Plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can have %dGB. User wants %dGB (plan: %s)",
			totalStorage, currentStorage+wantStorage, p.Plan)
	}

	p.Log.Debug("Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		p.Username, currentStorage, wantStorage, totalStorage, p.Plan)

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
	// index internally inside AWS so somehow that one is not timing out.
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
