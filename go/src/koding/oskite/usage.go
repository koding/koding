package oskite

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"koding/virt"
	"net/http"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Plan struct {
	CPU         int `json:"cpu"`
	RAM         int `json:"ram"`  // Memory usage in MB
	Disk        int `json:"disk"` // Disk in MB
	TotalVMs    int `json:"totalVMs"`
	AlwaysOnVMs int `json:"alwaysOnVMs"`
}

type PlanResponse struct {
	CPU         string `json:"cpu"`
	RAM         string `json:"ram"`  // Memory usage in MB
	Disk        string `json:"disk"` // Disk in MB
	TotalVMs    string `json:"totalVMs"`
	AlwaysOnVMs string `json:"alwaysOnVMs"`
}

type subscriptionResp struct {
	Plan string `json:"plan"`
}

var (
	plans = map[string]Plan{
		"free": {CPU: 1, RAM: 1000, Disk: 3000, TotalVMs: 1, AlwaysOnVMs: 0},
		"1x":   {CPU: 2, RAM: 2000, Disk: 10000, TotalVMs: 2, AlwaysOnVMs: 1},
		"2x":   {CPU: 4, RAM: 4000, Disk: 20000, TotalVMs: 4, AlwaysOnVMs: 2},
		"3x":   {CPU: 6, RAM: 6000, Disk: 40000, TotalVMs: 6, AlwaysOnVMs: 3},
		"4x":   {CPU: 8, RAM: 8000, Disk: 80000, TotalVMs: 8, AlwaysOnVMs: 4},
		"5x":   {CPU: 10, RAM: 10000, Disk: 100000, TotalVMs: 10, AlwaysOnVMs: 5},
	}

	okString      = "ok"
	quotaExceeded = "quota exceeded."
)

func NewPlanResponse() *PlanResponse {
	return &PlanResponse{
		CPU:         okString,
		RAM:         okString,
		Disk:        okString,
		TotalVMs:    okString,
		AlwaysOnVMs: okString,
	}
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

func (p *Plan) checkLimits(username string) (*PlanResponse, error) {
	planID, err := getSubscription(username)
	if err != nil {
		log.Critical("oskite checkLimits err: %v", err)
		return nil, errors.New("couldn't fetch subscription")
	}

	plan, ok := plans[planID]
	if !ok {
		return nil, errors.New("plan doesn't exist")
	}

	resp := NewPlanResponse()

	if p.AlwaysOnVMs >= plan.AlwaysOnVMs {
		resp.AlwaysOnVMs = quotaExceeded
	}

	if p.TotalVMs >= plan.TotalVMs {
		resp.TotalVMs = quotaExceeded
	}

	return resp, nil
}

func vmUsage(vos *virt.VOS, username string) (interface{}, error) {
	usage, err := NewUsage(vos)
	if err != nil {
		log.Info("vm.usage [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("vm.usage couldn't be retrieved. please consult to support.")
	}

	return usage.checkLimits(username)
}

type KiteStore struct {
	Id          bson.ObjectId `bson:"_id"`
	Name        string        `bson:"name"`
	Description string        `bson:"description"`
	KiteCode    string        `bson:"kiteCode"`
}

func getKiteCode() (string, error) {
	kiteStore := new(KiteStore)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"name": OSKITE_NAME}).One(kiteStore)
	}

	err := mongodbConn.Run("jKites", query)
	if err != nil {
		return "", err
	}

	return kiteStore.KiteCode, nil
}

func getSubscription(username string) (string, error) {
	endpointURL := "https://lvh.me:3020"

	code, err := getKiteCode()
	if err != nil {
		return "", err
	}

	if code == "" {
		return "", errors.New("kite code is empty")
	}

	resp, err := http.Get(endpointURL + "/-/subscription/check/" + code + "/" + username)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var s = new(subscriptionResp)
	if err := json.Unmarshal(body, s); err != nil {
		return "", errors.New("Subscription data is malformed")
	}

	return s.Plan, nil
}
