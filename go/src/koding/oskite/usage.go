package oskite

import (
	"fmt"
	"koding/db/models"
	"koding/virt"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Usage struct {
	CPU         int
	RAM         int
	Disk        int
	AlwaysOnVMs int
	TotalVMs    int
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

	fmt.Println("my vms are %+v\n", vms)
	return &Usage{}, nil
}

func vmUsage(vos *virt.VOS) (interface{}, error) {
	usage, err := NewUsage(vos)
	if err != nil {
		return nil, err
	}

	return usage, nil
}
