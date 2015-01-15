package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

func popMachinesForMetricGet(metricName string) ([]*models.Machine, error) {
	username, err := popFromQueue(metricName, GetQueueKey)
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return nil, err
	}

	return machines, nil
}
