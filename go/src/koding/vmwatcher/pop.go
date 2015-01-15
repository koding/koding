package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

func popMachinesForMetricGet(metric string) ([]*models.Machine, error) {
	return popMachine(metric, getQueueKey(GetKey))
}

func popMachinesOverLimit(metric, limit string) ([]*models.Machine, error) {
	return popMachine(metric, limit)
}

func popMachine(key, subkey string) ([]*models.Machine, error) {
	username, err := popFromQueue(key, subkey)
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return nil, err
	}

	return machines, nil
}
