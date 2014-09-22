package main

import (
	// "fmt"
	"math/rand"
	"strconv"
	"sync"
	"time"

	"koding/kites/kloud/idlock"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/koding"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
)

const username = "testuser25"

// TestStorage satisfies the Storage interface
type TestStorage struct{}

func (t *TestStorage) Get(id string) (*protocol.Machine, error) {
	return GetMachineData(id), nil
}

func (t *TestStorage) Update(id string, s *kloud.StorageData) error {
	machineData := GetMachineData(id)

	if s.Type == "build" {
		machineData.Builder["QueryString"] = s.Data["queryString"].(string)
		machineData.Builder["ipAddress"] = s.Data["ipAddress"].(string)
		machineData.Builder["instanceId"] = s.Data["instanceId"].(string)
		machineData.Builder["instanceName"] = s.Data["instanceName"].(string)
	}

	if s.Type == "info" {
		machineData.Builder["instanceName"] = s.Data["instanceName"].(string)
	}

	SetMachineData(id, machineData)

	return nil
}

func (t *TestStorage) UpdateState(id string, state machinestate.State) error {
	machineData := GetMachineData(id)
	machineData.State = state
	SetMachineData(id, machineData)
	return nil
}

// TestLocker satisfies the Locker interface
type TestLocker struct {
	*idlock.IdLock
}

func (l *TestLocker) Lock(id string) error {
	l.Get(id).Lock()
	return nil
}

func (l *TestLocker) Unlock(id string) {
	l.Get(id).Unlock()
}

// TestChecker satisfies Checker interface
type TestChecker struct{}

func (c *TestChecker) Total() error {
	println("************ total called")
	return nil
}

func (c *TestChecker) AlwaysOn() error {
	return nil
}

func (c *TestChecker) Timeout() error {
	return nil
}

func (c *TestChecker) Storage(int) error {
	return nil
}

func (c *TestChecker) AllowedInstances(koding.InstanceType) error {
	return nil
}

// Test Data

var (
	TestMachineData = make(map[string]*protocol.Machine)
	TestMu          sync.Mutex
)

func GetMachineData(id string) *protocol.Machine {
	TestMu.Lock()
	defer TestMu.Unlock()
	return TestMachineData[id]
}

func SetMachineData(id string, machine *protocol.Machine) {
	TestMu.Lock()
	defer TestMu.Unlock()
	TestMachineData[id] = machine
}

func init() {
	rand.Seed(time.Now().UnixNano())

	instanceName := "kloudtest-" + strconv.Itoa(rand.Intn(100000))
	instanceId := "i-" + strconv.Itoa(rand.Intn(100000))

	TestMachineData = map[string]*protocol.Machine{
		"koding_id0": &protocol.Machine{
			Id:       "koding_id0",
			Provider: "koding",
			Username: username,
			Builder: map[string]interface{}{
				"username":     username,
				"type":         "amazon",
				"region":       "us-east-1",
				"source_ami":   "ami-2651904e",
				"storage_size": 3,
				"alwaysOn":     false,
				"instanceName": instanceName,
				"instanceId":   instanceId,
			},
			Credential: map[string]interface{}{
				"username": "kodinginc",
				"apiKey":   "96d6388ccb936f047fd35eb29c36df17",
			},
			State: machinestate.NotInitialized,
			Domain: protocol.Domain{
				Name: "foo." + username + ".dev.koding.io",
			},
		},
	}
}
