package main

import (
	"github.com/koding/kloud"
	"github.com/koding/kloud/machinestate"
)

type TestStorageFunc func(id string, opt *kloud.GetOption) (*kloud.MachineData, error)

func (t TestStorageFunc) Get(id string, opt *kloud.GetOption) (*kloud.MachineData, error) {
	return t(id, opt)
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

func (t *TestStorage) Get(id string, opt *kloud.GetOption) (*kloud.MachineData, error) {
	machineData := TestProviderData[id]
	return machineData, nil
}

func (t *TestStorage) Update(id string, s *kloud.StorageData) error {
	machineData := TestProviderData[id]

	if s.Type == "build" {
		machineData.Machine.QueryString = s.Data["queryString"].(string)
		machineData.Machine.IpAddress = s.Data["ipAddress"].(string)
		machineData.Machine.Meta["instanceId"] = s.Data["instanceId"]
		machineData.Machine.Meta["instanceName"] = s.Data["instanceName"]
	}

	if s.Type == "info" {
		machineData.Machine.Meta["instanceName"] = s.Data["instanceName"]
	}

	TestProviderData[id] = machineData
	return nil
}

func (t *TestStorage) UpdateState(id string, state machinestate.State) error {
	machineData := TestProviderData[id]
	machineData.Machine.Status.State = state.String()
	TestProviderData[id] = machineData
	return nil
}

func (t *TestStorage) ResetAssignee(id string) error {
	return nil
}
