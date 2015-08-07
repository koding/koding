package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"sync"
)

var limitsToAction = map[string]func(string, string, string) error{
	StopLimitKey:  stopVMIfRunning,
	BlockLimitKey: blockUserAndDestroyVm,
}

type metricQueueMsg struct {
	Metric  Metric
	Machine *models.Machine
}

// pops username from set in db and gets metrics for machines belonging
// to that user; it uses pop instead of find so multiple workers can
// work in parallel
func getAndSaveQueueMachineMetrics() error {
	var index = 0
	defer func() {
		Log.Debug("Fetched: %d machine entries for queued usernames", index)
	}()

	var queue = make(chan *metricQueueMsg)
	var waitg sync.WaitGroup

	for i := 0; i < ParallelWorkerCount; i++ {
		waitg.Add(1)

		go func() {
			for msg := range queue {
				index += 1

				err := msg.Metric.GetAndSaveData(msg.Machine.Credential)
				if err != nil {
					Log.Error(err.Error())
				}
			}

			waitg.Done()
		}()
	}

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

			for i := range machines {
				queue <- &metricQueueMsg{Metric: metric, Machine: machines[i]}
			}
		}
	}

	close(queue)
	waitg.Wait()

	return nil
}

type actionQueueMsg struct {
	Machines []*models.Machine
	Limit    string
	Action   func(string, string, string) error
}

func dealWithMachinesOverLimit() error {
	var (
		queue = make(chan *actionQueueMsg)
		waitg sync.WaitGroup
	)

	for i := 0; i < ParallelWorkerCount; i++ {
		waitg.Add(1)

		go func() {
			for msg := range queue {
				act(msg.Machines, msg.Limit, msg.Action)
			}

			waitg.Done()
		}()
	}

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

				queue <- &actionQueueMsg{Machines: machines, Limit: limit, Action: action}
			}
		}
	}

	close(queue)
	waitg.Wait()

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
