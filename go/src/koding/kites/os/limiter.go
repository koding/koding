package main

import (
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
		for _, info := range infos {
			usage := ReadIntFile("/sys/fs/cgroup/memory/lxc/" + info.vmName + "/memory.usage_in_bytes")
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
		for _, info := range infos {
			newTotalCpuUsage := ReadIntFile("/sys/fs/cgroup/cpuacct/lxc/" + info.vmName + "/cpuacct.usage")

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

			info.PhysicalMemoryLimit = memoryLimit

			ioutil.WriteFile("/sys/fs/cgroup/cpu/lxc/"+info.vmName+"/cpu.shares", []byte(strconv.Itoa(info.CpuShares)), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/memory/lxc/"+info.vmName+"/memory.limit_in_bytes", []byte(strconv.Itoa(info.PhysicalMemoryLimit)), 0644)
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
