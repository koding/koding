package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"log"
)

func getAndSaveQueueMachineMetrics() error {
	for {
		machines, err := popMachinesForMetricGet()
		if err != nil {
			return err
		}

		if len(machines) == 0 {
			return nil
		}

		for _, machine := range machines {
			for _, metric := range metricsToSave {
				err := metric.GetAndSaveData(machine.Credential)
				if err != nil {
					log.Println(err)
				}
			}
		}
	}

	return nil
}

func stopMachinesOverLimit() error {
	for _, metric := range metricsToSave {
		machines, err := metric.GetMachinesOverLimit()
		if err != nil {
			log.Println(err)
			continue
		}

		for _, machine := range machines {
			username := machine.Credential

			yes, err := shouldStopMachine(metric.GetName(), username)
			if err != nil {
				return err
			}

			if yes {
				err = stopVm(machine.ObjectId.Hex())
				if err != nil {
					log.Println(err)
				}
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

	if len(machines) == 0 {
		return nil
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

func shouldStopMachine(metricName, username string) (bool, error) {
	plan, err := getPlanForUser(username)
	if err != nil {
		return false, err
	}

	if plan != "free" {
		return true, nil
	}

	isExempt, err := storage.ExemptGet(metricName, username)
	if err != nil {
		return false, err
	}

	if isExempt {
		return true, nil
	}

	return false, nil
}

func getPlanForUser(username string) (string, error) {
	return "", nil
}
