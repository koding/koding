// +build linux

package main

import (
	"fmt"
	"io/ioutil"
	"koding/kites/provisioning/container"
	"net"
	"strconv"
	"syscall"
	"time"
)

// Maximum duration of a free container that can be active.
const ContainerOnDuration = 15 * time.Minute

// Default container values
const MemoryTotalInMB = 1024
const DiskTotalInMB = 1200

const MegaByte = 1024 * 1024

type State struct {
	ContainerName string
	IP            net.IP
	ShutdownTimer *time.Timer
	ContainerInfo ContainerInfo `json:"systemInfo"`
}

// ContainerInfo contains the disk and memory usage of a container
type ContainerInfo struct {
	Disk   *Disk   `json:"disk"`
	Memory *Memory `json:"memory"`
}

type Disk struct {
	TotalInMB uint64 `json:"totalInMB"`
	UsageInMB uint64 `json:"usageInMB"`
	FreeInMB  uint64 `json:"freeInMB"`
}

type Memory struct {
	TotalInMB uint64 `json:"totalInMB"`
	UsageInMB uint64 `json:"usageInMB"`
	FreeInMB  uint64 `json:"freeInMB"`
}

// NewState creates and returns a State instance that contains the current
// state of a container.
func NewState(containerName string) *State {
	s := &State{
		ContainerName: containerName,
		ShutdownTimer: time.NewTimer(0),
	}

	s.ContainerInfo.Disk = diskStats(containerName)
	s.ContainerInfo.Memory = memoryStats(containerName)

	return s
}

// GetState returns a State instance for the given containerName. If there is
// not containerName available, it creates a new state and returns it.
func GetState(containerName string) *State {
	statesMu.Lock()
	defer statesMu.Unlock()

	state, found := states[containerName]
	if !found {
		state = NewState(containerName)
		states[containerName] = state
	}

	return state
}

// StartTimer starts the shutdown timer. After 15 minutes it stops and
// unprepares the container.
func (s *State) StartTimer() {
	log.Info("starting %s timer of container %s", ContainerOnDuration, s.ContainerName)

	s.ShutdownTimer = time.AfterFunc(ContainerOnDuration, func() {
		log.Info("shutdown timer of container %s has started", s.ContainerName)
		c := container.NewContainer(s.ContainerName)
		c.IP = s.IP

		log.Info("shutdown timer is stopping the container %s", s.ContainerName)
		err := c.Stop()
		if err != nil {
			fmt.Printf("ERROR: startTimer could not stop '%s'\n", err)
		}

		log.Info("shutdown timer is unpreparing the container %s", s.ContainerName)
		err = c.Unprepare()
		if err != nil {
			fmt.Printf("ERROR: startTimer could not unprepare '%s'\n", err)
		}
	})
}

// ResetTimer resets the shutdown timer. The timer then begins to counting
// again.
func (s *State) ResetTimer() {
	log.Info("resetting timer of container %s", s.ContainerName)
	s.ShutdownTimer.Reset(ContainerOnDuration)
}

// StopTime stops the shutdown timer. It needs to be started again with
// StartTimer().
func (s *State) StopTimer() {
	log.Info("stopping timer of container %s", s.ContainerName)
	s.ShutdownTimer.Stop()
}

// memoryStats returns the total, usage and free memory of the given container
func memoryStats(containerName string) *Memory {
	memFile := "/sys/fs/cgroup/memory/" + containerName + "/memory.usage_in_bytes"

	totalInMB := MemoryTotalInMB
	usageInMB := readIntFile(memFile) / MegaByte
	freeInMB := totalInMB - usageInMB

	return &Memory{
		TotalInMB: uint64(totalInMB),
		UsageInMB: uint64(usageInMB),
		FreeInMB:  uint64(freeInMB),
	}
}

// disktStats returns the total, usage and free space of the given container
func diskStats(containerName string) *Disk {
	s := syscall.Statfs_t{}
	path := fmt.Sprintf("/var/lib/lxc/%s/overlay", containerName)
	syscall.Statfs(path, &s)

	total := s.Blocks * uint64(s.Bsize)
	free := s.Bfree * uint64(s.Bsize)
	avail := s.Bavail * uint64(s.Bsize)
	usage := total - free

	fmt.Println("total, free, usage", total, free, usage, avail)

	return &Disk{
		TotalInMB: total / MegaByte,
		UsageInMB: usage / MegaByte,
		FreeInMB:  free / MegaByte,
	}
}

// readIntFile reads files that contains only integers and returns the content
// of that file. Usefull for lxc cgroup files that only contains integers.
func readIntFile(file string) int {
	str, err := ioutil.ReadFile(file)
	if err != nil {
		return 0
	}

	v, err := strconv.Atoi(string(str[:len(str)-1]))
	if err != nil {
		return 0
	}

	return v
}
