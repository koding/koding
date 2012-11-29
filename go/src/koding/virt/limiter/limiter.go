package main

import (
	"fmt"
	"io/ioutil"
	"strconv"
	"time"
)

type LimiterData struct {
	active        bool
	previousUsage int64
	shares        int64
}

func main() {
	datas := make(map[string]*LimiterData)

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

		// apply limits
		for name, data := range datas {
			str, err := ioutil.ReadFile(fmt.Sprintf("/sys/fs/cgroup/cpuacct/lxc/%s/cpuacct.usage", name))
			if err != nil {
				continue
			}
			usage, err := strconv.ParseInt(string(str[:len(str)-1]), 10, 0)
			if err != nil {
				panic(err)
			}

			var diff int64 = 0
			if usage > data.previousUsage {
				diff = usage - data.previousUsage
			}

			data.shares -= diff / 100000000
			data.shares += 1
			if data.shares < 1 {
				data.shares = 1
			}
			if data.shares > 1000 {
				data.shares = 1000
			}

			ioutil.WriteFile(fmt.Sprintf("/sys/fs/cgroup/cpu/lxc/%s/cpu.shares", name), []byte(strconv.FormatInt(data.shares, 10)), 0644)
			data.previousUsage = usage
		}

		time.Sleep(time.Second)
	}
}
