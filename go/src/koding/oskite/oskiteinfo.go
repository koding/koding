// +build linux

package oskite

import (
	"bytes"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"os/exec"
	"strings"

	kitelib "github.com/koding/kite"
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

func oskiteAllOld(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return oskiteAll(), nil
}

func oskiteAll() map[string]*OskiteInfo {
	oskitesMu.Lock()
	defer oskitesMu.Unlock()

	oskitesCopy := make(map[string]*OskiteInfo, len(oskites))
	for k, v := range oskites {
		oskitesCopy[k] = v
	}

	return oskitesCopy
}

func (o *Oskite) oskiteInfoNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return o.GetOskiteInfo(), nil
}

func oskiteAllNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return oskiteAll(), nil
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
