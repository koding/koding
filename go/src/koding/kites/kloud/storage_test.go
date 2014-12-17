package main

import (
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

// FIXME: Test multiple usernames which contain invalid characters such as .,_!
// and etc.
const username = "kloudtestuser"

var (
	TestMachineData = make(map[string]*protocol.Machine)
	TestMu          sync.Mutex
)

func init() {
	rand.Seed(time.Now().UnixNano())

	instanceName := "kloudtest-" + strconv.Itoa(rand.Intn(100000))

	TestMachineData = map[string]*protocol.Machine{
		"koding_id0": &protocol.Machine{
			Id:        "koding_id0",
			Provider:  "koding",
			Username:  username,
			IpAddress: "",
			Builder: map[string]interface{}{
				"username":      username,
				"type":          "amazon",
				"region":        "us-east-1",
				"source_ami":    "ami-2651904e",
				"storage_size":  3,
				"alwaysOn":      false,
				"instanceName":  instanceName,
				"instance_type": "t2.micro",
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

// TestDomainStorage satisfies the DomainStorage interface
type TestDomainStorage struct{}

func (t *TestDomainStorage) Add(*protocol.Domain) error { return nil }

func (t *TestDomainStorage) Delete(name string) error { return nil }

func (t *TestDomainStorage) UpdateMachine(name, machine string) error { return nil }

func (t *TestDomainStorage) Get(name string) (*protocol.Domain, error) { return nil, nil }

func (t *TestDomainStorage) GetByMachine(machine string) ([]*protocol.Domain, error) {
	return nil, nil
}

// TestStorage satisfies the Storage interface
type TestStorage struct{}

func (t *TestStorage) Get(id string) (*protocol.Machine, error) {
	return GetMachineData(id), nil
}

func (t *TestStorage) Delete(id string) error {
	// delete(TestMachineData, id)
	return nil
}

func (t *TestStorage) Update(id string, s *kloud.StorageData) error {
	machine := GetMachineData(id)

	switch s.Type {
	case "build", "reinit":
		machine.QueryString = s.Data["queryString"].(string)
		machine.IpAddress = s.Data["ipAddress"].(string)
		machine.Domain.Name = s.Data["domainName"].(string)
		machine.Builder["instanceId"] = s.Data["instanceId"]
		machine.Builder["instanceName"] = s.Data["instanceName"]
	case "start":
		machine.IpAddress = s.Data["ipAddress"].(string)
		machine.Domain.Name = s.Data["domainName"].(string)
		machine.Builder["instanceId"] = s.Data["instanceId"]
	case "stop", "resize":
		machine.IpAddress = s.Data["ipAddress"].(string)
	default:
		return nil
	}

	SetMachineData(id, machine)

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
	return nil
}

func (c *TestChecker) AlwaysOn() error {
	return nil
}

func (c *TestChecker) Timeout() error {
	return nil
}

func (c *TestChecker) Storage(wantStorage int) error {
	return nil
}

func (c *TestChecker) AllowedInstances(wantInstance koding.InstanceType) error {
	return nil
}

// Test Data
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

func newInstanceName() string {
	return "kloudtest-" + strconv.Itoa(rand.Intn(100000))
}
