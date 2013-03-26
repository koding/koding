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
		infosMutex.Lock()

		// collect memory stats and calculate limit
		vmCount := len(infos)
		memoryUsages := make([]int, 0, vmCount)
		for name, info := range infos {
			usage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.usage_in_bytes", name))
			info.MemoryUsage = usage
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
			if required > availableMemory {
				memoryLimit += availableMemory / (vmCount - i)
				availableMemory = 0
				break
			}
			memoryLimit += diff
			availableMemory -= required
		}
		memoryLimit += availableMemory
		if memoryLimit > MaxMemoryLimit {
			memoryLimit = MaxMemoryLimit
		}

		// apply limits
		for name, info := range infos {
			newTotalCpuUsage := ReadIntFile(fmt.Sprintf("/sys/fs/cgroup/cpuacct/lxc/%s/cpuacct.usage", name))

			info.CpuUsage = 0
			if newTotalCpuUsage > info.totalCpuUsage {
				info.CpuUsage = newTotalCpuUsage - info.totalCpuUsage
			}
			info.totalCpuUsage = newTotalCpuUsage

			info.CpuShares -= info.CpuUsage / 100000000
			info.CpuShares += 1
			if info.CpuShares < 1 {
				info.CpuShares = 1
			}
			if info.CpuShares > 1000 {
				info.CpuShares = 1000
			}

			info.MemoryLimit = memoryLimit

			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/cpu/lxc/%s/cpu.shares", name), []byte(strconv.Itoa(info.CpuShares)), 0644)
			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/memory/lxc/%s/memory.limit_in_bytes", name), []byte(strconv.Itoa(info.MemoryLimit)), 0644)
		}

		infosMutex.Unlock()
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
