package oskite

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/virt"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Plan struct {
	CPU         int `json:"cpu"`
	RAM         int `json:"ram"`
	Disk        int `json:"Disk"`
	TotalVMs    int `json:"totalVMs"`
	AlwaysOnVMs int `json:"alwaysOnVMs"`
}

var (
	ErrQuotaExceeded = errors.New("quota exceeded")

	plans = map[string]Plan{
		"Free": {CPU: 1, RAM: 1, Disk: 3, TotalVMs: 1, AlwaysOnVMs: 0},
		"1x":   {CPU: 2, RAM: 2, Disk: 10, TotalVMs: 2, AlwaysOnVMs: 1},
		"2x":   {CPU: 4, RAM: 4, Disk: 20, TotalVMs: 4, AlwaysOnVMs: 2},
		"3x":   {CPU: 6, RAM: 6, Disk: 40, TotalVMs: 6, AlwaysOnVMs: 3},
		"4x":   {CPU: 8, RAM: 8, Disk: 80, TotalVMs: 8, AlwaysOnVMs: 4},
		"5x":   {CPU: 10, RAM: 10, Disk: 100, TotalVMs: 10, AlwaysOnVMs: 5},
	}
)

func (p *Plan) checkLimits(planID string) error {
	plan, ok := plans[planID]
	if !ok {
		return errors.New("plan doesn't exist")
	}

	if p.AlwaysOnVMs >= plan.AlwaysOnVMs {
		return ErrQuotaExceeded
	}

	if p.TotalVMs >= plan.TotalVMs {
		return ErrQuotaExceeded
	}

	return nil
}

func NewUsage(vos *virt.VOS) (*Plan, error) {
	vms := make([]*models.VM, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"webHome": vos.VM.WebHome}).Iter().All(&vms)
	}

	err := mongodbConn.Run("jVMs", query)
	if err != nil {
		return nil, fmt.Errorf("vm fetching err for user %s. err: %s", vos.VM.WebHome, err)
	}

	usage := new(Plan)
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
