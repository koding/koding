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
		for name := range states {
			usage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.memsw.usage_in_bytes", name))
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
		for name, data := range states {
			cpuUsage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/cpuacct/lxc/%s/cpuacct.usage", name))

			diff := 0
			if cpuUsage > data.previousCpuUsage {
				diff = cpuUsage - data.previousCpuUsage
			}
			data.previousCpuUsage = cpuUsage

			data.cpuShares -= diff / 100000000
			data.cpuShares += 1
			if data.cpuShares < 1 {
				data.cpuShares = 1
			}
			if data.cpuShares > 1000 {
				data.cpuShares = 1000
			}

			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/cpu/lxc/%s/cpu.shares", name), []byte(strconv.Itoa(data.cpuShares)), 0644)
			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.limit_in_bytes", name), []byte(strconv.Itoa(memoryLimit)), 0644)
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
