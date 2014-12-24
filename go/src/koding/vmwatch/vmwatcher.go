package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"log"
)

func getAndSaveQueueMachineMetrics() error {
	machines, err := popMachinesForMetricGet()
	if err != nil {
		return err
	}

	for _, machine := range machines {
		for _, metric := range metricsToSave {
			err := metric.GetAndSaveData(machine.Credential)
			if err != nil {
				log.Println(err)
			}
		}
	}

	return nil
}

func stopVmsOverLimit() error {
	runningVms, err := getRunningVms()
	if err != nil {
		return err
	}

	for _, vm := range runningVms {
		for _, metric := range metricsToSave {
			resp := metric.IsUserOverLimit(vm.Credential)
			if !resp.OverLimit {
				continue
			}

			err := stopVm(vm.ObjectId.Hex())
			if err != nil {
				log.Println(err)
			}
		}
	}

	return nil
}

func queueUsernamesForMetricGet() error {
	machines, err := getRunningVms()
	if err != nil {
		return err
	}

	usernames := []interface{}{}
	for _, machine := range machines {
		usernames = append(usernames, machine.Credential)
	}

	return storage.Queue(NetworkOut, usernames)
}

func popMachinesForMetricGet() ([]*models.Machine, error) {
	username, err := storage.Pop(NetworkOut)
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return nil, err
	}

	return machines, nil
}

func getRunningVms() ([]*models.Machine, error) {
	return modelhelper.GetRunningVms()
}
