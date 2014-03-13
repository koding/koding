// +build linux

package oskite

import (
	"bytes"
	"fmt"
	kitelib "github.com/koding/kite"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os/exec"
	"strings"
)

type ByVM []*OskiteInfo

func (b ByVM) Len() int           { return len(b) }
func (b ByVM) Swap(i, j int)      { b[i], b[j] = b[j], b[i] }
func (b ByVM) Less(i, j int) bool { return b[i].ActiveVMs < b[j].ActiveVMs }

type OskiteInfo struct {
	QueuedVMs         int    `json:"queuedVMs"`
	QueueLimit        int    `json:"queueLimit"`
	ActiveVMs         int    `json:"activeVMs"` // by default 0
	ActiveVMsLimit    int    `json:"activeVMsLimit"`
	Version           string `json:"version"`
	ServiceUniquename string `json:"-"`
}

func (o *Oskite) GetOskiteInfo() *OskiteInfo {
	return &OskiteInfo{
		QueuedVMs:      int(currentQueueCount.Get()),
		QueueLimit:     len(prepareQueue),
		ActiveVMs:      currentVMS(),
		ActiveVMsLimit: o.ActiveVMsLimit,
		Version:        o.Version,
	}
}

func (o *Oskite) oskiteInfo(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return o.GetOskiteInfo(), nil
}

func oskiteAll(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return oskites, nil
}

func (o *Oskite) oskiteInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return o.GetOskiteInfo(), nil
}

func oskiteAllNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return oskites, nil
}

// currentVMS returns the number of available lxc containers on the running machine
func currentVMS() int {
	out, err := exec.Command("/usr/bin/lxc-ls", "--active").CombinedOutput()
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
