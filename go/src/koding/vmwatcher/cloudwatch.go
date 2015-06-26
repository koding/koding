package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/crowdmob/goamz/aws"
	"github.com/crowdmob/goamz/cloudwatch"
	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

var (
	AWS_NAMESPACE = "AWS/EC2"
	AWS_PERIOD    = 604800

	GB_TO_MB float64 = 1024

	auth aws.Auth
)

type Limits map[string]float64

type Cloudwatch struct {
	Name   string
	Limits Limits
}

func (c *Cloudwatch) GetName() string {
	return c.Name
}

func (c *Cloudwatch) GetLimit(name string) float64 {
	limit, _ := c.Limits[name]
	return limit
}

func (c *Cloudwatch) Save(username string, value float64) error {
	return storage.SaveScore(c.Name, username, value)
}

func (c *Cloudwatch) GetAndSaveData(username string) error {
	userMachines, err := modelhelper.GetMachinesByUsername(username)
	if err != nil {
		return err
	}

	var sum float64

	for _, machine := range userMachines {
		meta, ok := machine.Meta.(bson.M)
		if !ok {
			Log.Debug("queued machine has no `meta`", machine.ObjectId)
			continue
		}

		region, ok := meta["region"].(string)
		if !ok || isEmpty(region) {
			Log.Debug("queued machine has no `region`: %v", machine.ObjectId)
			continue
		}

		instanceId, ok := meta["instanceId"].(string)
		if !ok || isEmpty(instanceId) {
			Log.Debug("queued machine has no `instanceId`: %v", machine.ObjectId)
			continue
		}

		dimension := &cloudwatch.Dimension{
			Name:  "InstanceId",
			Value: instanceId,
		}

		cw, err := cloudwatch.NewCloudWatch(auth, aws.Regions[region].CloudWatchServicepoint)
		if err != nil {
			Log.Error("Failed to initialize cloudwatch client:", err)
			continue
		}

		request := &cloudwatch.GetMetricStatisticsRequest{
			Dimensions: []cloudwatch.Dimension{*dimension},
			Statistics: []string{cloudwatch.StatisticDatapointSum},
			MetricName: c.GetName(),
			EndTime:    time.Now(),
			StartTime:  now.BeginningOfWeek(),
			Period:     AWS_PERIOD,
			Namespace:  AWS_NAMESPACE,
		}

		response, err := cw.GetMetricStatistics(request)
		if err != nil {
			Log.Error("Failed to get request for machine: %s, %v", machine.ObjectId, err)
			continue
		}

		for _, raw := range response.GetMetricStatisticsResult.Datapoints {
			sum += raw.Sum / GB_TO_MB / GB_TO_MB
		}
	}

	if sum > c.Limits[StopLimitKey] {
		Log.Info("'%s' has used: %v '%s'", username, sum, c.Name)
	}

	return c.Save(username, sum)
}

func (c *Cloudwatch) GetMachinesOverLimit(limitName string) ([]*models.Machine, error) {
	limitAmount := c.Limits[limitName]

	usernames, err := storage.GetFromScore(c.Name, limitAmount)
	if err != nil {
		return nil, err
	}

	machines := []*models.Machine{}

	for _, username := range usernames {
		lr, err := c.IsUserOverLimit(username, limitName)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

		if !lr.CanStart {
			ms, err := modelhelper.GetMachinesByUsername(username)
			if err != nil {
				if err != mgo.ErrNotFound {
					Log.Error(err.Error())
				}
				continue
			}

			machines = append(machines, ms...)
		}
	}

	return machines, nil
}

func (c *Cloudwatch) IsUserOverLimit(username, limitKey string) (*LimitResponse, error) {
	canStart := &LimitResponse{CanStart: true}

	value, err := storage.GetScore(c.Name, username)
	if err != nil && !isRedisRecordNil(err) {
		return nil, err
	}

	yes, err := exemptFromStopping(c.Name, username)
	if err != nil {
		return nil, err
	}

	if yes {
		return canStart, nil
	}

	planTitle, err := getPlanForUser(username)
	if err != nil {
		Log.Debug(
			"Fetching plan for username: %s failed: %v, defaulting to paid",
			username, err,
		)

		planTitle = PaidPlan
	}

	limit, err := c.getUserLimit(username, limitKey, planTitle)
	if err != nil {
		return nil, err
	}

	lr := &LimitResponse{
		CanStart:     limit >= value,
		AllowedUsage: limit,
		CurrentUsage: value,
		Reason:       fmt.Sprintf("%s overlimit", c.GetName()),
	}

	return lr, nil
}

func (c *Cloudwatch) getUserLimit(username, limitKey, planTitle string) (float64, error) {
	var limit float64

	switch planTitle {
	case FreePlan:
		limit = c.Limits[limitKey]
	default:
		limit = c.Limits[limitKey] * PaidPlanMultiplier
	}

	userLimit, err := getUserLimit(username)
	if err != nil && !isRedisRecordNil(err) {
		return 0, err
	}

	if !isRedisRecordNil(err) {
		return userLimit, nil
	}

	return limit, nil
}

func isRedisRecordNil(err error) bool {
	return err != nil && err == redis.ErrNil
}

func isEmpty(s string) bool {
	return s == ""
}
