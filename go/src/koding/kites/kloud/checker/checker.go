package checker

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"

	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type KodingChecker struct {
	DB        *mongodb.MongoDB
	Log       logging.Logger
	AWSClient amazonClient

	networkUsageEndpoint string
}

type networkUsageResponse struct {
	CanStart     bool    `json:"canStart"`
	Reason       string  `json:"reason"`
	AllowedUsage float64 `json:"allowedUsage"`
	CurrentUsage float64 `json:"currentUsage"`
}

func (k *KodingChecker) NetworkUsage() error {
	if k.networkUsageEndpoint == "" {
		return errors.New("Network usage endpoint is not set")
	}

	networkEndpoint, err := url.Parse(k.networkUsageEndpoint)
	if err != nil {
		k.Log.Debug("Failed to parse network-usage endpoint: %v. err: %v",
			k.networkUsageEndpoint, err)
		return err
	}

	var account *models.Account
	if err := k.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": k.Username}).One(&account)
	}); err != nil {
		k.Log.Warning("Failed to fetch user information while checking network-usage. err: %v",
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
		k.Log.Warning("Failed to fetch network-usage because network-usage providing api host seems down. err: %v",
			err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		k.Log.Debug("Network-usage response code is not 200. It's %v",
			resp.StatusCode)
		return nil
	}

	if err := json.NewDecoder(resp.Body).Decode(&usageResponse); err != nil {
		k.Log.Warning("Failed to decode network-usage response. err: %v",
			err)
		return nil
	}
	if !usageResponse.CanStart {
		k.Log.Debug("Network-usage limit is reached. Allowed usage: %v MiB, Current usage: %v MiB",
			usageResponse.AllowedUsage, usageResponse.CurrentUsage)

		err := fmt.Errorf("%s; allowed: %v, current: %v",
			usageResponse.Reason, usageResponse.AllowedUsage,
			usageResponse.CurrentUsage,
		)

		return err
	}
	return nil
}

func (k *KodingChecker) AllowedInstances(p *Payment, wantInstance string) error {
	allowedInstances := k.Payment.Plan.Limits().AllowedInstances

	if _, ok := allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (k *KodingChecker) AlwaysOn() error {
	alwaysOnLimit := k.Payment.Plan.Limits().AlwaysOn

	// get all alwaysOn machines that belongs to this user
	alwaysOnMachines := 0
	if err := k.DB.Run("jMachines", func(c *mgo.Collection) error {
		var err error
		alwaysOnMachines, err = c.Find(bson.M{
			"credential":    k.Username,
			"meta.alwaysOn": true,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	k.Log.Debug("checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		alwaysOnMachines, alwaysOnLimit, k.Payment.Plan)

	// the user has still not reached the limit
	if alwaysOnMachines <= alwaysOnLimit {
		k.Log.Debug("allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			k.Username, alwaysOnMachines, alwaysOnLimit, k.Payment.Plan)
		return nil // allow user, it didn't reach the limit
	}

	k.Log.Info("denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		k.Username, alwaysOnMachines, alwaysOnLimit, k.Payment.Plan)
	return fmt.Errorf("total alwaysOn limit has been reached. Current count: %d Plan limit: %d",
		alwaysOnMachines, alwaysOnLimit)
}

func (k *KodingChecker) PlanState() error {
	// if the plan is expired there is no need to return the plan anymore
	if k.Payment.State != "" && strings.ToLower(k.Payment.State) == "expired" {
		return fmt.Errorf("[%s] Plan is expired", k.Id.Hex())
	}

	return nil
}

func (k *KodingChecker) Total() error {
	allowedMachines := k.Payment.Plan.Limits().Total

	instances, err := k.userInstances()

	// no match, allow to create instance
	if err == amazon.ErrNoInstances {
		k.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			k.Username, len(instances), allowedMachines, k.Payment.Plan)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		k.Log.Debug("denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			k.Username, len(instances), allowedMachines, k.Payment.Plan)
		return fmt.Errorf("total machine limit has been reached. Current count: %d Plan limit: %d",
			len(instances), allowedMachines)
	}

	k.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		k.Username, len(instances), allowedMachines, k.Payment.Plan)
	return nil
}

func (k *KodingChecker) SnapshotTotal() error {
	allowedSnapshotCount := k.Payment.Plan.Limits().SnapshotTotal

	// lazy return
	if allowedSnapshotCount == 0 {
		k.Log.Debug("denying user to for snapshots, limit is zero already")
		return fmt.Errorf("total snapshot limit has been reached. Plan limit: %d", allowedSnapshotCount)
	}

	currentSnapshotCount := 0
	if err := k.DB.Run("jSnapshots", func(c *mgo.Collection) error {
		var err error
		currentSnapshotCount, err = c.Find(bson.M{
			"machineId": k.Id,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	k.Log.Debug("checking snapshot limit. current count: %d, plan limit: %d (plan: %s)",
		currentSnapshotCount, allowedSnapshotCount, k.Payment.Plan)

	// the user has still not reached the limit
	if currentSnapshotCount <= allowedSnapshotCount {
		k.Log.Debug("allowing user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
			k.Username, currentSnapshotCount, allowedSnapshotCount, k.Payment.Plan)
		return nil // allow user, it didn't reach the limit
	}

	k.Log.Info("denying user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
		k.Username, currentSnapshotCount, allowedSnapshotCount, k.Payment.Plan)
	return fmt.Errorf("total snapshot limit has been reached. Current count: %d Plan limit: %d",
		currentSnapshotCount, allowedSnapshotCount)

}

func (k *KodingChecker) Storage(wantStorage int) error {
	totalStorage := k.Payment.Plan.Limits().Storage

	// no need for errors because instances will be empty in case of an error
	instances, _ := k.userInstances()

	// we need to fetch JAccount here to get earnedRewards if exists
	var account *models.Account
	if err := k.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": k.Username}).One(&account)
	}); err != nil {
		k.Log.Warning("Failed to fetch user information while checking storage. err: %v",
			err)
		return err
	}

	rewardAmount := 0

	// querying the earnedReward of given account
	var reward *models.EarnedReward
	if err := k.DB.Run("jEarnedRewards", func(c *mgo.Collection) error {
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
			volumes, err := k.AWSClient.Client.Volumes([]string{blockDevice.VolumeId}, ec2.NewFilter())
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

	k.Log.Debug("Checking storage. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		currentStorage, wantStorage, totalStorage, k.Payment.Plan)

	if currentStorage+wantStorage > totalStorage {
		return fmt.Errorf("total storage limit has been reached. Can have %dGB. User wants %dGB (plan: %s)",
			totalStorage, currentStorage+wantStorage, k.Payment.Plan)
	}

	k.Log.Debug("Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		k.Username, currentStorage, wantStorage, totalStorage, k.Payment.Plan)

	// allow to create storage
	return nil
}

func (k *KodingChecker) userInstances() ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-value", k.Username)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := k.AWSClient.InstancesByFilter(filter)
	if err != nil {
		return nil, err
	}

	filtered := []ec2.Instance{}

	// we don't use filters because they are timing out for us due to high
	// instances count we have. However it seems the filter `tag-value` has an
	// index internally inside AWS so somehow that one is not timing out.
	for _, instance := range instances {
		for _, tag := range instance.Tags {
			if tag.Key == "koding-user" && tag.Value == k.Username {
				for _, tag := range instance.Tags {
					if tag.Key == "koding-env" && tag.Value == k.Kite.Config.Environment {

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
