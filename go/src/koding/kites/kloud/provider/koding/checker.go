package koding

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"koding/db/models"
	"koding/kites/kloud/api/amazon"

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

type networkUsageResponse struct {
	CanStart     bool    `json:"canStart"`
	Reason       string  `json:"reason"`
	AllowedUsage float64 `json:"allowedUsage"`
	CurrentUsage float64 `json:"currentUsage"`
}

func (m *Machine) NetworkUsage() error {
	if m.networkUsageEndpoint == "" {
		return errors.New("Network usage endpoint is not set")
	}

	networkEndpoint, err := url.Parse(m.networkUsageEndpoint)
	if err != nil {
		m.Log.Debug("Failed to parse network-usage endpoint: %v. err: %v",
			m.networkUsageEndpoint, err)
		return err
	}

	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": m.Username}).One(&account)
	}); err != nil {
		m.Log.Warning("Failed to fetch user information while checking network-usage. err: %v",
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
		m.Log.Warning("Failed to fetch network-usage because network-usage providing api host seems down. err: %v",
			err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		m.Log.Debug("Network-usage response code is not 200. It's %v",
			resp.StatusCode)
		return nil
	}

	if err := json.NewDecoder(resp.Body).Decode(&usageResponse); err != nil {
		m.Log.Warning("Failed to decode network-usage response. err: %v",
			err)
		return nil
	}
	if !usageResponse.CanStart {
		m.Log.Debug("Network-usage limit is reached. Allowed usage: %v MiB, Current usage: %v MiB",
			usageResponse.AllowedUsage, usageResponse.CurrentUsage)

		err := fmt.Errorf("%s; allowed: %v, current: %v",
			usageResponse.Reason, usageResponse.AllowedUsage,
			usageResponse.CurrentUsage,
		)

		return err
	}
	return nil
}

func (m *Machine) AllowedInstances(wantInstance InstanceType) error {
	allowedInstances := m.Payment.Plan.Limits().AllowedInstances

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (m *Machine) AlwaysOn() error {
	alwaysOnLimit := m.Payment.Plan.Limits().AlwaysOn

	// get all alwaysOn machines that belongs to this user
	alwaysOnMachines := 0
	if err := m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		var err error
		alwaysOnMachines, err = c.Find(bson.M{
			"credential":    m.Username,
			"meta.alwaysOn": true,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	m.Log.Debug("checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		alwaysOnMachines, alwaysOnLimit, m.Payment.Plan)

	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		m.Log.Debug("allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			m.Username, alwaysOnMachines, alwaysOnLimit, m.Payment.Plan)
		return nil // allow user, it didn't reach the limit
	}

	m.Log.Info("denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		m.Username, alwaysOnMachines, alwaysOnLimit, m.Payment.Plan)
	return fmt.Errorf("total alwaysOn limit has been reached. Current count: %d Plan limit: %d",
		alwaysOnMachines, alwaysOnLimit)
}

func (m *Machine) PlanState() error {
	// if the plan is expired there is no need to return the plan anymore
	if m.Payment.State != "" && strings.ToLower(m.Payment.State) == "expired" {
		return fmt.Errorf("[%s] Plan is expired", m.Id.Hex())
	}

	return nil
}

func (m *Machine) Total() error {
	allowedMachines := m.Payment.Plan.Limits().Total

	instances, err := m.userInstances()

	// no match, allow to create instance
	if err == amazon.ErrNoInstances {
		m.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			m.Username, len(instances), allowedMachines, m.Payment.Plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		m.Log.Debug("denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			m.Username, len(instances), allowedMachines, m.Payment.Plan)
		return fmt.Errorf("total machine limit has been reached. Current count: %d Plan limit: %d",
			len(instances), allowedMachines)
	}

	m.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		m.Username, len(instances), allowedMachines, m.Payment.Plan)
	return nil
}

func (m *Machine) SnapshotTotal() error {
	allowedSnapshotCount := m.Payment.Plan.Limits().SnapshotTotal

	// lazy return
	if allowedSnapshotCount == 0 {
		m.Log.Debug("denying user to for snapshots, limit is zero already")
		return fmt.Errorf("total snapshot limit has been reached. Plan limit: %d", allowedSnapshotCount)
	}

	currentSnapshotCount := 0
	if err := m.Session.DB.Run("jSnapshots", func(c *mgo.Collection) error {
		var err error
		currentSnapshotCount, err = c.Find(bson.M{
			"machineId": m.Id,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	m.Log.Debug("checking snapshot limit. current count: %d, plan limit: %d (plan: %s)",
		currentSnapshotCount, allowedSnapshotCount, m.Payment.Plan)

	// the user has still not reached the limit
	if currentSnapshotCount <= allowedSnapshotCount {
		m.Log.Debug("allowing user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
			m.Username, currentSnapshotCount, allowedSnapshotCount, m.Payment.Plan)
		return nil // allow user, it didn't reach the limit
	}

	m.Log.Info("denying user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
		m.Username, currentSnapshotCount, allowedSnapshotCount, m.Payment.Plan)
	return fmt.Errorf("total snapshot limit has been reached. Current count: %d Plan limit: %d",
		currentSnapshotCount, allowedSnapshotCount)

}

func (m *Machine) Storage(wantStorage int) error {
	totalStorage := m.Payment.Plan.Limits().Storage

	// no need for errors because instances will be empty in case of an error
	instances, _ := m.userInstances()

	// we need to fetch JAccount here to get earnedRewards if exists
	var account *models.Account
	if err := m.Session.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": m.Username}).One(&account)
	}); err != nil {
		m.Log.Warning("Failed to fetch user information while checking storage. err: %v",
			err)
		return err
	}

	rewardAmount := 0

	// querying the earnedReward of given account
	var reward *models.EarnedReward
	if err := m.Session.DB.Run("jEarnedRewards", func(c *mgo.Collection) error {
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
			volumes, err := m.Session.AWSClient.Client.Volumes([]string{blockDevice.VolumeId}, ec2.NewFilter())
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

	m.Log.Debug("Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		currentStorage, wantStorage, totalStorage, m.Payment.Plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can have %dGB. User wants %dGB (plan: %s)",
			totalStorage, currentStorage+wantStorage, m.Payment.Plan)
	}

	m.Log.Debug("Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		m.Username, currentStorage, wantStorage, totalStorage, m.Payment.Plan)

	// allow to create storage
	return nil
}

func (m *Machine) userInstances() ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-value", m.Username)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := m.Session.AWSClient.InstancesByFilter(filter)
	if err != nil {
		return nil, err
	}

	filtered := []ec2.Instance{}

	// we don't use filters because they are timing out for us due to high
	// instances count we have. However it seems the filter `tag-value` has an
	// index internally inside AWS so somehow that one is not timing out.
	for _, instance := range instances {
		for _, tag := range instance.Tags {
			if tag.Key == "koding-user" && tag.Value == m.Username {
				for _, tag := range instance.Tags {
					if tag.Key == "koding-env" && tag.Value == m.Session.Kite.Config.Environment {

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
