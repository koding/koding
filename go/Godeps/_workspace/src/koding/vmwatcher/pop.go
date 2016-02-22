package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

func popMachinesForMetricGet(metric string) ([]*models.Machine, error) {
	return popMachine(metric, getQueueKey(GetKey))
}

func popMachinesOverLimit(metric, limit string) ([]*models.Machine, error) {
	return popMachine(metric, getQueueKey(limit))
}

func popMachine(key, subkey string) ([]*models.Machine, error) {
	username, err := storage.Pop(key, subkey)
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesByUsername(username)
	if err != nil {
		return nil, err
	}

	return machines, nil
}
