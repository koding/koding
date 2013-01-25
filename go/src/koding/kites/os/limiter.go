package main

import (
	"fmt"
	"io/ioutil"
	"sort"
	"strconv"
	"time"
)

const MaxMemoryLimit = 1024 * 1024 * 1024

func LimiterLoop() {
	totalRAM := GetTotalRAM()

	for {
		statesMutex.Lock()

		// collect memory stats and calculate limit
		vmCount := len(states)
		memoryUsages := make([]int, 0, vmCount)
		for name, state := range states {
			usage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.usage_in_bytes", name))
			state.MemoryUsage = usage
			memoryUsages = append(memoryUsages, usage)
		}
		sort.Ints(memoryUsages)
		memoryLimit := 0
		availableMemory := totalRAM
		previousMemoryUsage := 0
		for i, memoryUsage := range memoryUsages {
			diff := memoryUsage - previousMemoryUsage
			previousMemoryUsage = memoryUsage
			required := diff * (vmCount - i)
			if required <= availableMemory {
				memoryLimit += diff
				availableMemory -= required
			} else {
				memoryLimit += availableMemory / (vmCount - i)
				availableMemory = 0
				break
			}
		}
		memoryLimit += availableMemory
		if memoryLimit > MaxMemoryLimit {
			memoryLimit = MaxMemoryLimit
		}

		// apply limits
		for name, state := range states {
			newTotalCpuUsage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/cpuacct/lxc/%s/cpuacct.usage", name))

			state.CpuUsage = 0
			if newTotalCpuUsage > state.totalCpuUsage {
				state.CpuUsage = newTotalCpuUsage - state.totalCpuUsage
			}
			state.totalCpuUsage = newTotalCpuUsage

			state.CpuShares -= state.CpuUsage / 100000000
			state.CpuShares += 1
			if state.CpuShares < 1 {
				state.CpuShares = 1
			}
			if state.CpuShares > 1000 {
				state.CpuShares = 1000
			}

			state.MemoryLimit = memoryLimit

			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/cpu/lxc/%s/cpu.shares", name), []byte(strconv.Itoa(state.CpuShares)), 0644)
			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.limit_in_bytes", name), []byte(strconv.Itoa(state.MemoryLimit)), 0644)
		}

		statesMutex.Unlock()
		time.Sleep(time.Second)
	}
}

func ReadIntFile(file string) int {
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
