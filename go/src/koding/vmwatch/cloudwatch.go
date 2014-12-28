package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"log"

	"github.com/crowdmob/goamz/aws"
	"github.com/crowdmob/goamz/cloudwatch"
	"github.com/jinzhu/now"
	"labix.org/v2/mgo/bson"
)

var (
	AWS_KEY       = "AKIAIWHOKFWDYNSQFGCQ"
	AWS_SECRET    = "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"
	AWS_NAMESPACE = "AWS/EC2"
	AWS_PERIOD    = 604800

	today        = now.BeginningOfDay()
	sevenDaysAgo = today.Add(-7 * 24 * time.Hour)

	auth aws.Auth

	useAwsDefaultRegion = false
	awsDefaultRegion    aws.ServiceInfo

	NetworkOut = "NetworkOut"
)

func init() {
	var err error

	auth, err = aws.GetAuth(AWS_KEY, AWS_SECRET, "", now.BeginningOfDay())
	if err != nil {
		log.Fatal("Error: %+v\n", err)
	}
}

type Cloudwatch struct {
	Name string
}

func (c *Cloudwatch) GetName() string {
	return c.Name
}

func (c *Cloudwatch) GetAndSaveData(username string) error {
	userMachines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return err
	}

	var sum float64

	for _, machine := range userMachines {
		var meta = machine.Meta.(bson.M)
		var regionStr = meta["region"].(string)
		var instanceId = meta["instance_id"].(string)

		dimension := &cloudwatch.Dimension{
			Name:  "InstanceId",
			Value: instanceId,
		}

		cw, err := cloudwatch.NewCloudWatch(auth, aws.Regions[regionStr].CloudWatchServicepoint)
		if err != nil {
			return err
		}

		request := &cloudwatch.GetMetricStatisticsRequest{
			Dimensions: []cloudwatch.Dimension{*dimension},
			Statistics: []string{cloudwatch.StatisticDatapointSum},
			MetricName: c.Name,
			EndTime:    today,
			StartTime:  sevenDaysAgo,
			Period:     AWS_PERIOD,
			Namespace:  AWS_NAMESPACE,
		}

		response, err := cw.GetMetricStatistics(request)
		if err != nil {
			return err
		}

		for _, raw := range response.GetMetricStatisticsResult.Datapoints {
			sum += raw.Sum / 1024 / 1024
		}
	}

	return storage.Save(c.Name, username, sum)
}

func (c *Cloudwatch) GetMachinesOverLimit() ([]*models.Machine, error) {
	usernames, err := storage.Range(c.Name, NetworkOutLimt)
	if err != nil {
		return nil, err
	}

	machines := []*models.Machine{}

	for _, username := range usernames {
		ms, err := modelhelper.GetMachinesForUsername(username)
		if err != nil {
			log.Println(err)
			continue
		}

		machines = append(machines, ms...)
	}

	return machines, nil
}

func (c *Cloudwatch) IsUserOverLimit(username string) (*LimitResponse, error) {
	value, err := storage.Get(c.GetName(), username)
	if err != nil {
		return nil, err
	}

	lr := &LimitResponse{
		OverLimit:    value >= NetworkOutLimt,
		AllowedUsage: NetworkOutLimt,
		CurrentUsage: value,
	}

	return lr, err
}
