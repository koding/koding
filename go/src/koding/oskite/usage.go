package oskite

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/virt"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Usage struct {
	CPU         int `json:"cpu"`
	RAM         int `json:"ram"`
	Disk        int `json:"disk"`
	AlwaysOnVMs int `json:"alwaysOnVMs"`
	TotalVMs    int `json:"totalVMs"`
}

func NewUsage(vos *virt.VOS) (*Usage, error) {
	vms := make([]*models.VM, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"webHome": vos.VM.WebHome}).Iter().All(&vms)
	}

	err := mongodbConn.Run("jVMs", query)
	if err != nil {
		return nil, fmt.Errorf("vm fetching err for user %s. err: %s", vos.VM.WebHome, err)
	}

	usage := new(Usage)
	usage.TotalVMs = len(vms)

	for _, vm := range vms {
		if vm.AlwaysOn {
			usage.AlwaysOnVMs++
		}

		usage.CPU += vm.NumCPUs
		usage.RAM += vm.MaxMemoryInMB
		usage.Disk += vm.DiskSizeInMB
	}

	return usage, nil
}

func vmUsage(vos *virt.VOS) (interface{}, error) {
	usage, err := NewUsage(vos)
	if err != nil {
		log.Info("vm.usage [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("vm.usage couldn't be retrieved. please consult to support.")
	}

	return usage, nil
}
