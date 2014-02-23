// +build linux

package main

import (
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os/exec"
	"strings"
)

type OskiteInfo struct {
	CurrentQueue int `json:"currentQueue"`
	MaxQueue     int `json:"maxQueue"`
	CurrentVMS   int `json:"currentVMS"`
}

func GetOskiteInfo() *OskiteInfo {
	return &OskiteInfo{
		CurrentQueue: len(prepareQueue),
		MaxQueue:     prepareQueueLimit,
		CurrentVMS:   currentVMS(),
	}
}

func oskiteInfo(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return GetOskiteInfo(), nil
}

// currentVMS returns the number of available lxc containers on the running machine
func currentVMS() int {
	out, err := exec.Command("/usr/bin/lxc-ls").CombinedOutput()
	if err != nil {
		fmt.Println(err)
		return 0
	}

	count := 0
	for _, container := range strings.Split(string(out), " ") {
		if strings.HasPrefix(container, "vm-") {
			count++
		}
	}

	return count
}
