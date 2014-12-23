package main

import (
	"koding/db/models"
	"log"
	"time"
)

func getAndSaveRunningVmsMetrics() error {
	runningVms, err := getRunningVms()
	if err != nil {
		return err
	}

	for _, vm := range runningVms {
		for _, metric := range metricsToSave {
			err := metric.GetAndSaveData(vm.ObjectId.Hex(), time.Now())
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
			resp := metric.IsVmOverLimit(vm.ObjectId.Hex(), time.Now())
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

func getRunningVms() ([]models.Machine, error) {
	return []models.Machine{}, nil
}
