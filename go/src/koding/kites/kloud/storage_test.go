package main

import (
	"github.com/koding/kloud"
	"github.com/koding/kloud/idlock"
	"github.com/koding/kloud/machinestate"
)

var locks = idlock.New()

type TestStorageFunc func(id string) (*kloud.Machine, error)

func (t TestStorageFunc) Get(id string) (*kloud.Machine, error) {
	return t(id)
}

func (t TestStorageFunc) Update(id string, data *kloud.StorageData) error {
	return nil
}

func (t TestStorageFunc) UpdateState(id string, state machinestate.State) error {
	return nil
}

func (t TestStorageFunc) Assignee() string {
	return "TestStorageFunc"
}

func (t TestStorageFunc) ResetAssignee(id string) error {
	return nil
}

type TestStorage struct{}

func (t *TestStorage) Assignee() string { return "TestStorage" }

func (t *TestStorage) Get(id string) (*kloud.Machine, error) {
	machineData := GetTestData(id)
	locks.Get(testuser).Lock()
	return machineData, nil
}

func (t *TestStorage) Update(id string, s *kloud.StorageData) error {
	machineData := GetTestData(id)

	if s.Type == "build" {
		machineData.Data["queryString"] = s.Data["queryString"].(string)
		machineData.Data["ipAddress"] = s.Data["ipAddress"].(string)
		machineData.Data["instanceId"] = s.Data["instanceId"].(string)
		machineData.Data["instanceName"] = s.Data["instanceName"].(string)
	}

	if s.Type == "info" {
		machineData.Data["instanceName"] = s.Data["instanceName"].(string)
	}

	TestData[id] = machineData
	return nil
}

func (t *TestStorage) UpdateState(id string, state machinestate.State) error {
	machineData := GetTestData(id)
	machineData.State = state
	TestData[id] = machineData
	return nil
}

func (t *TestStorage) ResetAssignee(id string) error {
	locks.Get(testuser).Unlock()
	return nil
}
