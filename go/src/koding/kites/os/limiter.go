package main

import (
	"io/ioutil"
	"koding/virt"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

const MaxMemoryLimit = 1024 * 1024 * 1024

type SortableByCpuUsage []*VMInfo

func (s SortableByCpuUsage) Len() int {
	return len(s)
}

func (s SortableByCpuUsage) Less(i, j int) bool {
	return s[i].CpuUsage > s[j].CpuUsage
}

func (s SortableByCpuUsage) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

func LimiterLoop() {
	totalRAM := GetTotalRAM()

	for {
		infosMutex.Lock()

		// collect stats
		vmCount := len(infos)
		memoryUsages := make([]int, 0, vmCount)
		for _, info := range infos {
			newTotalCpuUsage := ReadIntFile("/sys/fs/cgroup/cpuacct/lxc/" + virt.VMName(info.vmId) + "/cpuacct.usage")
			info.CpuUsage = 0
			if newTotalCpuUsage > info.totalCpuUsage {
				info.CpuUsage = newTotalCpuUsage - info.totalCpuUsage
			}
			info.totalCpuUsage = newTotalCpuUsage

			usage := ReadIntFile("/sys/fs/cgroup/memory/lxc/" + virt.VMName(info.vmId) + "/memory.usage_in_bytes")
			info.MemoryUsage = usage
			memoryUsages = append(memoryUsages, usage)
		}

		// calculate cores
		list := make(SortableByCpuUsage, 0, len(infos))
		for _, info := range infos {
			list = append(list, info)
		}
		sort.Sort(list)
		cpus := make([]int, runtime.NumCPU())
		for _, info := range list {
			taken := make([]bool, len(cpus))
			for i := range info.currentCpus {
				cpuIndex := 0
				for j, usage := range cpus {
					if usage < cpus[cpuIndex] && !taken[j] {
						cpuIndex = j
					}
				}
				info.currentCpus[i] = strconv.Itoa(cpuIndex)
				taken[cpuIndex] = true
				cpus[cpuIndex] += info.CpuUsage / len(info.currentCpus)
			}
		}

		// calculate memory limit
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
			info.CpuShares -= info.CpuUsage / 100000000
			info.CpuShares += 1
			if info.CpuShares < 1 {
				info.CpuShares = 1
			}
			if info.CpuShares > 1000 {
				info.CpuShares = 1000
			}

			info.PhysicalMemoryLimit = memoryLimit

			ioutil.WriteFile("/sys/fs/cgroup/cpu/lxc/"+virt.VMName(info.vmId)+"/cpu.shares", []byte(strconv.Itoa(info.CpuShares)), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/cpuset/lxc/"+virt.VMName(info.vmId)+"/cpuset.cpus", []byte(strings.Join(info.currentCpus, ",")), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/memory/lxc/"+virt.VMName(info.vmId)+"/memory.limit_in_bytes", []byte(strconv.Itoa(info.PhysicalMemoryLimit)), 0644)
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
