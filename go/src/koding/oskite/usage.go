package oskite

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
	"net/http"

	"gopkg.in/fatih/set.v0"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type LimitState int

const (
	LimitOk LimitState = iota
	LimitQuotaExceeded
)

type Limit struct {
	CPU         LimitState `bson:"cpu"`
	RAM         LimitState `bson:"ram"`  // Memory usage in MB
	Disk        LimitState `bson:"disk"` // Disk in MB
	TotalVMs    LimitState `bson:"totalVMs"`
	AlwaysOnVMs LimitState `bson:"alwaysOnVMs"`
}

type LimitError struct {
	Message string `json:"message"`
	Code    string `json:"code"`
}

func (l *LimitError) Error() string {
	out, err := json.Marshal(l)
	if err != nil {
		panic(err) // should never happen
	}

	return string(out)
}

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

type subscriptionResp struct {
	PlanName string `json:"planName"`
	PlanId   string `json:"planId"`
	Err      string `json:"err"`
}

var (
	// [N]x = [Nx2] CPU + [Nx2]GB Ram + [Nx10]GB Disk + [Nx10] Total VM + [N] Always On (devrim's forumla)
	plans = map[string]Plan{
		"free": {CPU: 1, RAM: 1000, Disk: 3000, TotalVMs: 5, AlwaysOnVMs: 0},
		"1x":   {CPU: 2, RAM: 2000, Disk: 10000, TotalVMs: 10, AlwaysOnVMs: 1},
		"2x":   {CPU: 4, RAM: 4000, Disk: 20000, TotalVMs: 20, AlwaysOnVMs: 2},
		"3x":   {CPU: 6, RAM: 6000, Disk: 30000, TotalVMs: 30, AlwaysOnVMs: 3},
		"4x":   {CPU: 8, RAM: 8000, Disk: 40000, TotalVMs: 40, AlwaysOnVMs: 4},
		"5x":   {CPU: 10, RAM: 10000, Disk: 50000, TotalVMs: 50, AlwaysOnVMs: 5},

		"10x":  {CPU: 20, RAM: 20000, Disk: 100000, TotalVMs: 100, AlwaysOnVMs: 10},
		"25x":  {CPU: 50, RAM: 50000, Disk: 250000, TotalVMs: 250, AlwaysOnVMs: 25},
		"50x":  {CPU: 100, RAM: 100000, Disk: 500000, TotalVMs: 500, AlwaysOnVMs: 50},
		"75x":  {CPU: 150, RAM: 150000, Disk: 700000, TotalVMs: 750, AlwaysOnVMs: 75},
		"100x": {CPU: 200, RAM: 200000, Disk: 1000000, TotalVMs: 1000, AlwaysOnVMs: 100},
	}

	ErrQuotaExceeded = errors.New("quota exceeded")

	kiteCode string

	endpointErrs = set.New(
		errors.New("TOKEN_REQUIRED"),
		errors.New("USERNAME_REQUIRED"),
		errors.New("GROUPNAME_REQUIRED"),
		errors.New("KITE_NOT_FOUND"),
		errors.New("USER_NOT_FOUND"),
		errors.New("GROUP_NOT_FOUND"),
		errors.New("NOT_A_MEMBER_OF_GROUP"),
		errors.New("KITE_HAS_NO_PLAN"),
		errors.New("NO_SUBSCRIPTION"),
	)
)

func newLimit() *Limit {
	return &Limit{
		CPU:         LimitOk,
		RAM:         LimitOk,
		Disk:        LimitOk,
		TotalVMs:    LimitOk,
		AlwaysOnVMs: LimitOk,
	}
}

func vmUsage(args *dnode.Partial, vos *virt.VOS, username string) (interface{}, error) {
	var params struct {
		GroupId string
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empy argument passed"}
	}

	if args.Unmarshal(&params) != nil || params.GroupId == "" {
		return nil, &kite.ArgumentError{Expected: "{ groupId: [string] }"}
	}

	usage, err := totalUsage(vos, params.GroupId)
	if err != nil {
		log.Info("vm.usage [%s] err: %v", vos.VM.HostnameAlias, err)
		return nil, errors.New("vm.usage couldn't be retrieved. please consult to support.")
	}

	limits, err := usage.prepareLimits(username, params.GroupId)
	if err != nil {
		return nil, err
	}

	if err := limits.check(); err != nil {
		return nil, err
	}

	return true, nil
}

func totalUsage(vos *virt.VOS, groupId string) (*Plan, error) {
	if !bson.IsObjectIdHex(groupId) {
		return nil, fmt.Errorf("groupID %s is not valid hex representation", groupId)
	}

	vms := make([]*models.VM, 0)

	// db.jVMs.find({"webHome":"foo", "groups": {$in:[{"id":ObjectId("5196fcb2bc9bdb0000000027")}]}})
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"webHome":  vos.VM.WebHome,
			"hostKite": bson.M{"$ne": nil},
			"groups":   bson.M{"$in": []bson.M{bson.M{"id": bson.ObjectIdHex(groupId)}}},
		}).Iter().All(&vms)
	}

	if err := mongodbConn.Run("jVMs", query); err != nil {
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

func (p *Plan) prepareLimits(username, groupId string) (*Limit, error) {
	sub, err := getSubscription(username, groupId)
	if err != nil {
		log.Warning("oskite checkLimits err: %v", err)
		return nil, errors.New("couldn't fetch subscription")
	}

	if sub.PlanName == "" {
		return nil, errors.New("planName is empty")
	}
	fmt.Printf("sub %+v\n", sub)

	plan, ok := plans[sub.PlanName]
	if !ok {
		return nil, errors.New("plan doesn't exist")
	}

	lim := newLimit()
	if p.AlwaysOnVMs > plan.AlwaysOnVMs {
		lim.AlwaysOnVMs = LimitQuotaExceeded
	}

	if p.TotalVMs >= plan.TotalVMs {
		lim.TotalVMs = LimitQuotaExceeded
	}

	if p.CPU >= plan.CPU {
		lim.CPU = LimitQuotaExceeded
	}

	if p.RAM >= plan.RAM {
		lim.RAM = LimitQuotaExceeded
	}

	if p.Disk >= plan.Disk {
		lim.Disk = LimitQuotaExceeded
	}

	return lim, nil
}

func (l *Limit) check() error {
	fmt.Printf("limits %+v\n", l)

	if l.AlwaysOnVMs == LimitQuotaExceeded {
		return &LimitError{Message: "AlwaysOnVMs limit reached.", Code: ErrQuotaExceeded.Error()}
	}

	if l.CPU == LimitQuotaExceeded {
		return &LimitError{Message: "CPU limit reached", Code: ErrQuotaExceeded.Error()}
	}

	if l.Disk == LimitQuotaExceeded {
		return &LimitError{Message: "Disk limit reached", Code: ErrQuotaExceeded.Error()}
	}

	if l.RAM == LimitQuotaExceeded {
		return &LimitError{Message: "Ram limit reached", Code: ErrQuotaExceeded.Error()}
	}

	return nil
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

func getSubscription(username, groupId string) (*subscriptionResp, error) {
	code, err := getKiteCode()
	if err != nil {
		return nil, err
	}

	if code == "" {
		return nil, errors.New("kite code is empty")
	}

	endpointURL := conf.SubscriptionEndpoint + code + "/" + username + "/" + groupId

	fmt.Printf("endpointURL %+v\n", endpointURL)

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
