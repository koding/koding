package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

var limitsToAction = map[string]func(string, string, string) error{
	StopLimitKey:  stopVm,
	BlockLimitKey: blockUserAndDestroyVm,
}

// pops username from set in db and gets metrics for machines belonging
// to that user; it uses pop instead of find so multiple workers can
// work in parallel
func getAndSaveQueueMachineMetrics() error {
	var index = 0
	defer func() {
		Log.Debug("Fetched: %d machine entries for queued usernames", index)
	}()

	for _, metric := range metricsToSave {
		for {
			machines, err := popMachinesForMetricGet(metric.GetName())
			if err != nil {
				if !isRedisRecordNil(err) {
					Log.Error("Failed to fetching machines for %s, %v", metric.GetName(), err)
				}

				// ran out of usernames in queue, so go next metric
				break
			}

			// username has no machine, possibly due to it being deleted since the
			// machine was queued, go to next queued username
			if len(machines) == 0 {
				continue
			}

			for _, machine := range machines {
				index += 1

				err := metric.GetAndSaveData(machine.Credential)
				if err != nil {
					Log.Error(err.Error())
				}
			}
		}
	}

	return nil
}

func dealWithMachinesOverLimit() error {
	for _, metric := range metricsToSave {
		for limit, action := range limitsToAction {
			for {
				machines, err := popMachinesOverLimit(metric.GetName(), limit)
				if err != nil && !isRedisRecordNil(err) {
					Log.Error(err.Error())
					continue
				}

				if isRedisRecordNil(err) {
					break
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

var KodingProvider = "koding"

func getRunningVms() ([]*models.Machine, error) {
	return modelhelper.GetRunningVms(KodingProvider)
}

func extractUsernames(machines []*models.Machine) []interface{} {
	usernames := []interface{}{}
	for _, machine := range machines {
		usernames = append(usernames, machine.Credential)
	}

	return usernames
}

func act(machines []*models.Machine, limit string, fn func(string, string, string) error) error {
	for _, machine := range machines {
		err := fn(machine.ObjectId.Hex(), machine.Credential, limit)
		if err != nil {
			Log.Error(err.Error())
			continue
		}
	}

	return nil
}
