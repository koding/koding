package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

var limitsToAction = map[string]func(string, string) error{
	StopLimitKey:  stopVm,
	BlockLimitKey: blockUserAndDestroyVm,
}

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

func dealWithMachinesOverLimit() error {
	for _, metric := range metricsToSave {
		for limit, action := range limitsToAction {
			for {
				machines, err := popMachinesOverLimit(metric.GetName(), limit)
				if err != nil {
					Log.Error(err.Error())
					continue
				}

				Log.Debug(
					"Fetched: %d machines that are overlimit: %s for metric: %s#%s",
					len(machines), metric.GetName(), limit,
				)

				act(machines, limit, action)
			}
		}
	}

	return nil
}

func getRunningVms() ([]models.Machine, error) {
	return modelhelper.GetRunningVms()
}

func extractUsernames(machines []*models.Machine) []interface{} {
	usernames := []interface{}{}
	for _, machine := range machines {
		usernames = append(usernames, machine.Credential)
	}

	return usernames
}

func act(machines []*models.Machine, limit string, fn func(string, string) error) error {
	for _, machine := range machines {
		err := fn(machine.ObjectId.Hex(), limit)
		if err != nil {
			Log.Error(err.Error())
			continue
		}
	}

	return nil
}
