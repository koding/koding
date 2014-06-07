package main

import (
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
)

type TestStorageFunc func(id string, opt *kloud.GetOption) (*kloud.MachineData, error)

func (t TestStorageFunc) Get(id string, opt *kloud.GetOption) (*kloud.MachineData, error) {
	return t(id, opt)
}

func (t TestStorageFunc) Update(id string, resp *protocol.BuildResponse) error  { return nil }
func (t TestStorageFunc) UpdateState(id string, state machinestate.State) error { return nil }

func (t TestStorageFunc) GetState(id string) (machinestate.State, error) {
	return machinestate.Running, nil
}

type TestStorage struct{}

func (t *TestStorage) Get(id string, opt *kloud.GetOption) (*kloud.MachineData, error) {
	machineData := TestProviderData[id]
	return machineData, nil
}

func (t *TestStorage) Update(id string, resp *protocol.BuildResponse) error {
	machineData := TestProviderData[id]
	machineData.Machine.QueryString = resp.QueryString
	machineData.Machine.IpAddress = resp.IpAddress
	machineData.Machine.Meta["instanceName"] = resp.InstanceName
	machineData.Machine.Meta["instanceId"] = strconv.Itoa(resp.InstanceId)

	TestProviderData[id] = machineData
	return nil
}

func (t *TestStorage) UpdateState(id string, state machinestate.State) error {
	machineData := TestProviderData[id]
	machineData.Machine.Status.State = state.String()
	TestProviderData[id] = machineData
	return nil
}

func (t *TestStorage) GetState(id string) (machinestate.State, error) {
	return machinestate.States[TestProviderData[id].Machine.Status.State], nil
}
