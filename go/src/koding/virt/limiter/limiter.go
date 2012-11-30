package main

import (
	"fmt"
	"io/ioutil"
	"sort"
	"strconv"
	"time"
)

type LimiterData struct {
	active           bool
	previousCpuUsage int
	cpuShares        int
}

const MAX_MEMORY_LIMIT = 1024 * 1024 * 1024

func main() {
	datas := make(map[string]*LimiterData)
	totalRAM := GetTotalRAM()

	for {
		// add/remove map entries
		for _, data := range datas {
			data.active = false
		}
		infos, err := ioutil.ReadDir("/sys/fs/cgroup/cpuacct/lxc")
		if err != nil {
			panic(err)
		}
		for _, info := range infos {
			if info.IsDir() {
				data := datas[info.Name()]
				if data != nil {
					data.active = true
				} else {
					datas[info.Name()] = &LimiterData{true, 1<<63 - 1, 1000}
				}
			}
		}
		for name, data := range datas {
			if !data.active {
				delete(datas, name)
			}
		}

		// collect memory stats and calculate limit
		groupCount := len(datas)
		memoryUsages := make([]int, 0, groupCount)
		for name := range datas {
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
			required := diff * (groupCount - i)
			if required <= availableMemory {
				memoryLimit += diff
				availableMemory -= required
			} else {
				memoryLimit += availableMemory / (groupCount - i)
				availableMemory = 0
				break
			}
		}
		memoryLimit += availableMemory
		if memoryLimit > MAX_MEMORY_LIMIT {
			memoryLimit = MAX_MEMORY_LIMIT
		}

		// apply limits
		for name, data := range datas {
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
