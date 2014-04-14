package oskite

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"net/http"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	ErrTokenRequired    = "TOKEN_REQUIRED"
	ErrUsernameRequired = "USERNAME_REQUIRED"
	ErrGroupRequired    = "GROUPNAME_REQUIRED"
	ErrKiteNotFound     = "KITE_NOT_FOUND"
	ErrUserNotFound     = "USER_NOT_FOUND"
	ErrGroupNotFound    = "GROUP_NOT_FOUND"
	ErrInvalid          = "NOT_A_MEMBER_OF_GROUP"
	ErrKiteNoPlan       = "KITE_HAS_NO_PLAN"
	ErrNoSubscription   = "NO_SUBSCRIPTION"
)

type KiteStore struct {
	Id       bson.ObjectId `bson:"_id"`
	Name     string        `bson:"name"`
	KiteCode string        `bson:"kiteCode"`
	Manifest struct {
		Description string `bson:"description"`
		Name        string `bson:"name"`
		Readme      string `bson:"readme"`
		AuthorNick  string `bson:"authorNick"`
		Author      string `bson:"author"`
	}
}

type Plan struct {
	CPU         int `bson:"cpu"`
	RAM         int `bson:"ram"`  // Memory usage in MB
	Disk        int `bson:"disk"` // Disk in MB
	TotalVMs    int `bson:"totalVMs"`
	AlwaysOnVMs int `bson:"alwaysOnVMs"`
}

type PlanResponse struct {
	CPU         string `bson:"cpu"`
	RAM         string `bson:"ram"`  // Memory usage in MB
	Disk        string `bson:"disk"` // Disk in MB
	TotalVMs    string `bson:"totalVMs"`
	AlwaysOnVMs string `bson:"alwaysOnVMs"`
}

type subscriptionResp struct {
	Plan   string `json:"plan"`
	PlanId string `json:"planId"`
	Err    string `json:"err"`
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
	kiteCode      string
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

func vmUsage(args *dnode.Partial, vos *virt.VOS, username string) (interface{}, error) {
	var params struct {
		GroupName string
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empy argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.GroupName == "" {
		return nil, &kite.ArgumentError{Expected: "{ groupName: [string] }"}
	}

	usage, err := NewUsage(vos, params.GroupName)
	if err != nil {
		log.Info("vm.usage [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("vm.usage couldn't be retrieved. please consult to support.")
	}

	return usage.checkLimits(username, params.GroupName)
}

func NewUsage(vos *virt.VOS, groupname string) (*Plan, error) {
	group, err := modelhelper.GetGroup(groupname)
	if err != nil {
		return nil, fmt.Errorf("modelhelper.GetGroup: %s", err)
	}

	vms := make([]*models.VM, 0)

	// db.jVMs.find({"webHome":"foo", "groups": {$in:[{"id":ObjectId("5196fcb2bc9bdb0000000027")}]}})
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"webHome": vos.VM.WebHome,
			"groups":  bson.M{"$in": []bson.M{bson.M{"id": group.Id}}},
		}).Iter().All(&vms)
	}

	err = mongodbConn.Run("jVMs", query)
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

	fmt.Printf("usage %+v\n", usage)
	return usage, nil
}

func (p *Plan) checkLimits(username, groupname string) (*PlanResponse, error) {
	sub, err := getSubscription(username, groupname)
	if err != nil {
		log.Warning("oskite checkLimits err: %v", err)
		return nil, errors.New("couldn't fetch subscription")
	}

	if sub.PlanId == "" {
		return nil, errors.New("planID is empty")
	}

	plan, ok := plans[sub.PlanId]
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

// getKiteCode returns the API token to be used with Koding's subscription
// endpoint.
func getKiteCode() (string, error) {
	if kiteCode != "" {
		return kiteCode, nil
	}

	kiteStore := new(KiteStore)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"name": "OsKite"}).One(kiteStore)
	}

	err := mongodbConn.Run("jKites", query)
	if err != nil {
		return "", err
	}

	kiteCode = kiteStore.KiteCode

	return kiteStore.KiteCode, nil
}

func getSubscription(username, groupname string) (*subscriptionResp, error) {
	code, err := getKiteCode()
	if err != nil {
		return nil, err
	}

	if code == "" {
		return nil, errors.New("kite code is empty")
	}

	endpointURL := conf.SubscriptionEndpoint + code + "/" + username + "/" + groupname

	resp, err := http.Get(endpointURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var sub = new(subscriptionResp)
	if err := json.Unmarshal(body, sub); err != nil {
		return nil, errors.New("Subscription data is malformed")
	}

	if resp.StatusCode != 200 {
		if sub.Err != "" {
			return nil, errors.New(sub.Err)
		}
		return nil, errors.New("api not allowed")
	}

	return sub, nil
}
