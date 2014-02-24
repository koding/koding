// +build linux

package main

import (
	"bytes"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os/exec"
	"strings"
)

type OskiteInfo struct {
	QueuedVMs       int    `json:"queuedVMs,omitempty"`
	QueueLimit      int    `json:"queueLimit,omitempty"`
	CurrentVMs      int    `json:"currentVMs"` // by default 0
	CurrentVMsLimit int    `json:"currentVMsLimit,omitempty"`
	Version         string `json:"version"`
}

func GetOskiteInfo() *OskiteInfo {
	return &OskiteInfo{
		QueuedVMs:       len(prepareQueue),
		QueueLimit:      prepareQueueLimit,
		CurrentVMs:      currentVMS(),
		CurrentVMsLimit: *flagLimit,
		Version:         OSKITE_VERSION,
	}
}

func oskiteInfo(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return GetOskiteInfo(), nil
}

func oskiteAll(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return oskites, nil
}

// currentVMS returns the number of available lxc containers on the running machine
func currentVMS() int {
	out, err := exec.Command("/usr/bin/lxc-ls").CombinedOutput()
	if err != nil {
		fmt.Println(err)
		return 0
	}

	shellOut := string(bytes.TrimSpace(out))
	if shellOut == "" {
		return 0
	}

	count := 0
	for _, container := range strings.Split(shellOut, "\n") {
		if strings.HasPrefix(container, "vm-") {
			count++
		}
	}

	return count
}
