package plans

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"

	"koding/db/models"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/session"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type KodingChecker struct {
	NetworkUsageEndpoint string
}

func (k *KodingChecker) Fetch(ctx context.Context, planName string) (Checker, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("Koding checker couldn't obtain session context")
	}

	if k.NetworkUsageEndpoint == "" {
		return nil, errors.New("Network usage endpoint is not set")
	}

	plan, ok := Plans[planName]
	if !ok {
		return nil, fmt.Errorf("could not find plan. There is no plan called '%s'", planName)
	}

	plan.networkUsageEndpoint = k.NetworkUsageEndpoint
	plan.DB = sess.DB
	plan.AWSClient = sess.AWSClient
	plan.Environment = sess.Kite.Config.Environment
	plan.Log = sess.Log

	return plan, nil
}

type networkUsageResponse struct {
	CanStart     bool    `json:"canStart"`
	Reason       string  `json:"reason"`
	AllowedUsage float64 `json:"allowedUsage"`
	CurrentUsage float64 `json:"currentUsage"`
}

func (p *Plan) NetworkUsage(username string) error {
	if p.networkUsageEndpoint == "" {
		return errors.New("Network usage endpoint is not set")
	}

	networkEndpoint, err := url.Parse(p.networkUsageEndpoint)
	if err != nil {
		p.Log.Debug("Failed to parse network-usage endpoint: %v. err: %v",
			p.networkUsageEndpoint, err)
		return err
	}

	var account *models.Account
	if err := p.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
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

func (p *Plan) AllowedInstances(wantInstance InstanceType) error {
	if _, ok := p.allowedInstances[wantInstance]; ok {
		return nil
	}

	return fmt.Errorf("not allowed to create instance type: %s", wantInstance)
}

func (p *Plan) AlwaysOn(username string) error {
	// get all alwaysOn machines that belongs to this user
	alwaysOnMachines := 0
	if err := p.DB.Run("jMachines", func(c *mgo.Collection) error {
		var err error
		alwaysOnMachines, err = c.Find(bson.M{
			"credential":    username,
			"meta.alwaysOn": true,
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	p.Log.Debug("checking alwaysOn limit. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		alwaysOnMachines, p.AlwaysOnLimit, p)

	// the user has still not reached the limit
	if alwaysOnMachines <= p.AlwaysOnLimit {
		p.Log.Debug("allowing user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
			username, alwaysOnMachines, p.AlwaysOnLimit, p)
		return nil // allow user, it didn't reach the limit
	}

	p.Log.Info("denying user '%s'. current alwaysOn count: %d (plan limit: %d, plan: %s)",
		username, alwaysOnMachines, p.AlwaysOnLimit, p)
	return fmt.Errorf("total alwaysOn limit has been reached. Current count: %d Plan limit: %d",
		alwaysOnMachines, p.AlwaysOnLimit)
}

func (p *Plan) Total(username string) error {
	instances, err := p.userInstances(username)

	// no match, allow to create instance
	if err == amazon.ErrNoInstances {
		p.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			username, len(instances), p.TotalLimit, p)
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= p.TotalLimit {
		p.Log.Debug("denying user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
			username, len(instances), p.TotalLimit, p)
		return fmt.Errorf("total machine limit has been reached. Current count: %d Plan limit: %d",
			len(instances), p.TotalLimit)
	}

	p.Log.Debug("allowing user '%s'. current machine count: %d (plan limit: %d, plan: %s)",
		username, len(instances), p.TotalLimit, p)
	return nil
}

func (p *Plan) SnapshotTotal(machineId, username string) error {
	// lazy return
	if p.SnapshotTotalLimit == 0 {
		p.Log.Debug("denying user to for snapshots, limit is zero already")
		return fmt.Errorf("total snapshot limit has been reached. Plan limit: %d", p.SnapshotTotalLimit)
	}

	currentSnapshotCount := 0
	if err := p.DB.Run("jSnapshots", func(c *mgo.Collection) error {
		var err error
		currentSnapshotCount, err = c.Find(bson.M{
			"machineId": bson.ObjectIdHex(machineId),
		}).Count()

		return err
	}); err != nil && err != mgo.ErrNotFound {
		// if it's something else just return an error, needs to be fixed
		return err
	}

	p.Log.Debug("checking snapshot limit. current count: %d, plan limit: %d (plan: %s)",
		currentSnapshotCount, p.SnapshotTotalLimit, p)

	// the user has still not reached the limit
	if currentSnapshotCount <= p.SnapshotTotalLimit {
		p.Log.Debug("allowing user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
			username, currentSnapshotCount, p.SnapshotTotalLimit, p)
		return nil // allow user, it didn't reach the limit
	}

	p.Log.Info("denying user '%s'. current snapshot count: %d (plan limit: %d, plan: %s)",
		username, currentSnapshotCount, p.SnapshotTotalLimit, p)
	return fmt.Errorf("total snapshot limit has been reached. Current count: %d Plan limit: %d",
		currentSnapshotCount, p.SnapshotTotalLimit)
}

func (p *Plan) Storage(wantStorage int, username string) error {
	// no need for errors because instances will be empty in case of an error
	instances, _ := p.userInstances(username)

	// we need to fetch JAccount here to get earnedRewards if exists
	var account *models.Account
	if err := p.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
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

	// and adding it to p.StorageLimit
	// if there is no reward it will be 0 in this state
	p.StorageLimit += rewardAmount

	// i hate for loops too, but unfortunaly the responses are always in form
	// of slices
	currentStorage := 0
	for _, instance := range instances {
		for _, blockDevice := range instance.BlockDevices {
			volumes, err := p.AWSClient.Client.Volumes([]string{blockDevice.VolumeId}, ec2.NewFilter())
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
		currentStorage, wantStorage, p.StorageLimit, p)

	if currentStorage+wantStorage > p.StorageLimit {
		return fmt.Errorf("total storage limit has been reached. Can have %dGB. User wants %dGB (plan: %s)",
			p.StorageLimit, currentStorage+wantStorage, p)
	}

	p.Log.Debug("Allowing user '%s'. Current: %dGB. Want: %dGB (plan limit: %dGB, plan: %s)",
		username, currentStorage, wantStorage, p.StorageLimit, p)

	// allow to create storage
	return nil
}

func (p *Plan) userInstances(username string) ([]ec2.Instance, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-value", username)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := p.AWSClient.InstancesByFilter(filter)
	if err != nil {
		return nil, err
	}

	filtered := []ec2.Instance{}

	// we don't use filters because they are timing out for us due to high
	// instances count we have. However it seems the filter `tag-value` has an
	// index internally inside AWS so somehow that one is not timing out.
	for _, instance := range instances {
		for _, tag := range instance.Tags {
			if tag.Key == "koding-user" && tag.Value == username {
				for _, tag := range instance.Tags {
					if tag.Key == "koding-env" && tag.Value == p.Environment {

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
