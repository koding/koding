package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"strings"
)

// pops username from set in db and gets metrics for machines belonging
// to that user; it uses pop instead of find so multiple workers can
// work in parallel
func getAndSaveQueueMachineMetrics() error {
	var index = 0
	defer func() {
		Log.Debug("Fetched: %d entries for queued usernames", index)
	}()

	for {
		for _, metric := range metricsToSave {
			machines, err := popMachinesForMetricGet(metric.GetName())
			if err != nil {
				// ran out of usernames in queue, so return
				if isRedisRecordNil(err) {
					return nil
				}
			}

			if len(machines) == 0 {
				continue
			}

			for _, machine := range machines {
				err := metric.GetAndSaveData(machine.Credential)
				if err != nil {
					Log.Error(err.Error())
				}
			}
		}

		index += 1
	}

	return nil
}

func stopMachinesOverLimit() error {
	for _, metric := range metricsToSave {
		machines, err := metric.GetMachinesOverLimit(NetworkOutLimit)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

		Log.Debug(
			"Fetched: %d machines that are overlimit for metric: %s",
			len(machines), metric.GetName(),
		)

		if len(machines) == 0 {
			continue
		}

		var stopSuccess = 0

		for _, machine := range machines {
			reason := fmt.Sprintf(
				"%v overlimit, allowed: %d", metric.GetName(), metric.GetLimit(),
			)

			err = stopVm(machine.ObjectId.Hex(), reason)
			if err != nil {
				if !strings.Contains(err.Error(), "not allowed for current state") {
					Log.Error("Error: %s for username: %s", err.Error(), machine.Credential)
				}

				continue
			}

			stopSuccess += 1
		}

		Log.Debug(
			"Successfully stopped: %d/%d overlimit machines for metric: %s",
			stopSuccess, len(machines), metric.GetName(),
		)
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

	for _, metric := range metricsToSave {
		Log.Debug("Queued: %d usernames for metric: %s", len(usernames), metric.GetName())

		err := newStorage.Save(metric.GetName(), QueueName, usernames)
		if err != nil {
			return err
		}
	}

	return nil
}

func popMachinesForMetricGet(metricName string) ([]*models.Machine, error) {
	username, err := newStorage.Pop(metricName, QueueName)
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesForUsername(username)
	if err != nil {
		return nil, err
	}

	return machines, nil
}

func getRunningVms() ([]models.Machine, error) {
	return modelhelper.GetRunningVms()
}
