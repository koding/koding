// +build linux

package main

import (
	"io/ioutil"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

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
			newTotalCpuUsage := ReadIntFile("/sys/fs/cgroup/cpuacct/lxc/" + info.vm.String() + "/cpuacct.usage")
			info.CpuUsage = 0
			if newTotalCpuUsage > info.totalCpuUsage {
				info.CpuUsage = newTotalCpuUsage - info.totalCpuUsage
			}
			info.totalCpuUsage = newTotalCpuUsage

			usage := ReadIntFile("/sys/fs/cgroup/memory/lxc/" + info.vm.String() + "/memory.usage_in_bytes")
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
			if len(info.currentCpus) != info.vm.NumCPUs {
				info.currentCpus = make([]string, info.vm.NumCPUs)
			}
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
			info.TotalMemoryLimit = info.vm.MaxMemoryInMB * 1024 * 1024
			if info.PhysicalMemoryLimit > info.TotalMemoryLimit {
				info.PhysicalMemoryLimit = info.TotalMemoryLimit
			}

			ioutil.WriteFile("/sys/fs/cgroup/cpu/lxc/"+info.vm.String()+"/cpu.shares", []byte(strconv.Itoa(info.CpuShares)), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/cpuset/lxc/"+info.vm.String()+"/cpuset.cpus", []byte(strings.Join(info.currentCpus, ",")), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/memory/lxc/"+info.vm.String()+"/memory.limit_in_bytes", []byte(strconv.Itoa(info.PhysicalMemoryLimit)), 0644)
			ioutil.WriteFile("/sys/fs/cgroup/memory/lxc/"+info.vm.String()+"/memory.memsw.limit_in_bytes", []byte(strconv.Itoa(info.TotalMemoryLimit)), 0644)
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
