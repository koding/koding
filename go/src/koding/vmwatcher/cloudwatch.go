package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

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

	rightNow = time.Now()

	auth aws.Auth

	PaidPlanMultiplier float64 = 2
)

type Cloudwatch struct {
	Name  string
	Limit float64
}

func (c *Cloudwatch) GetName() string {
	return c.Name
}

func (c *Cloudwatch) GetLimit() float64 {
	limit, _ := storage.GetLimit(c.GetName(), c.Limit)
	return limit
}

func isEmpty(s string) bool {
	return s == ""
}

func (c *Cloudwatch) GetAndSaveData(username string) error {
	userMachines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return err
	}

	var sum float64

	for _, machine := range userMachines {
		meta, ok := machine.Meta.(bson.M)
		if !ok {
			Log.Error("queued machine has no `meta`", machine.ObjectId)
			continue
		}

		region, ok := meta["region"].(string)
		if !ok || isEmpty(region) {
			Log.Error("queued machine has no `region`: %v", machine.ObjectId)
			continue
		}

		instanceId, ok := meta["instanceId"].(string)
		if !ok || isEmpty(instanceId) {
			Log.Error("queued machine has no `instanceId`: %v", machine.ObjectId)
			continue
		}

		dimension := &cloudwatch.Dimension{
			Name:  "InstanceId",
			Value: instanceId,
		}

		cw, err := cloudwatch.NewCloudWatch(auth, aws.Regions[region].CloudWatchServicepoint)
		if err != nil {
			Log.Error("Failed to initialize cloudwatch client", err)
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
			Log.Error("Failed to get request for machine: %v", machine.ObjectId)
			continue
		}

		for _, raw := range response.GetMetricStatisticsResult.Datapoints {
			sum += raw.Sum / GB_TO_MB / GB_TO_MB
		}
	}

	if sum > c.Limit {
		Log.Debug("'%s' has used: %v '%s'", username, sum, c.Name)
	}

	return storage.Save(c.Name, username, sum)
}

func (c *Cloudwatch) GetMachinesOverLimit() ([]*models.Machine, error) {
	usernames, err := storage.Range(c.Name, c.GetLimit())
	if err != nil {
		return nil, err
	}

	machines := []*models.Machine{}

	for _, username := range usernames {
		lr, err := c.IsUserOverLimit(username)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

		if !lr.CanStart {
			ms, err := modelhelper.GetMachinesForUsername(username)
			if err != nil {
				Log.Error(err.Error())
				continue
			}

			machines = append(machines, ms...)
		}
	}

	return machines, nil
}

func (c *Cloudwatch) IsUserOverLimit(username string) (*LimitResponse, error) {
	canStart := &LimitResponse{CanStart: true}

	value, err := storage.Get(c.GetName(), username)
	if err != nil && !isRedisRecordNil(err) {
		return nil, err
	}

	yes, err := exemptFromStopping(c.GetName(), username)
	if err != nil {
		return nil, err
	}

	if yes {
		return canStart, nil
	}

	planTitle, err := getPlanForUser(username)
	if err != nil {
		return nil, err
	}

	var limit float64

	switch planTitle {
	case FreePlan:
		limit = c.GetLimit()
	default:
		limit = c.GetLimit() * PaidPlanMultiplier
	}

	lr := &LimitResponse{
		CanStart:     limit >= value,
		AllowedUsage: limit,
		CurrentUsage: value,
		Reason:       fmt.Sprintf("%s overlimit", c.GetName()),
	}

	return lr, nil
}

func (c *Cloudwatch) RemoveUsername(username string) error {
	return storage.Remove(c.GetName(), username)
}

func isRedisRecordNil(err error) bool {
	return err != nil && err == redis.ErrNil
}
