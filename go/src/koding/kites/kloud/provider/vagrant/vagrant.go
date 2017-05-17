package vagrant

import (
	"errors"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/utils"
	"net/url"
	"strconv"
)

var p = &provider.Provider{
	Name:         "vagrant",
	ResourceName: "instance",
	Machine:      newMachine,
	Stack:        newStack,
	NoCloudInit:  true,
	Schema: &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  nil,
		NewMetadata:   newMetadata,
	},
}

func init() {
	provider.Register(p)
}

// Cred represents jCredentialDatas.meta for "vagrant" provider.
type Cred struct {
	QueryString string `json:"queryString" bson:"queryString" hcl:"queryString"`
	Memory      int    `json:"memory" bson:"memory" hcl:"memory"`
	CPU         int    `json:"cpus" bson:"cpus" hcl:"cpus"`
	Box         string `json:"box" bson:"box" hcl:"box"`
}

var _ stack.Validator = (*Cred)(nil)

// Valid implements the kloud.Validator interface.
func (meta *Cred) Valid() error {
	if meta.QueryString == "" {
		return errors.New("vagrant meta: query string is empty")
	}

	query, err := utils.QueryString(meta.QueryString)
	if err != nil {
		return err
	}

	meta.QueryString = query

	return nil
}

func newCredential() interface{} {
	return &Cred{}
}

type Meta struct {
	AlwaysOn    bool   `bson:"alwaysOn"`
	StorageSize int    `bson:"storage_size"`
	FilePath    string `bson:"filePath"`
	Box         string `bson:"box"`
	Memory      int    `bson:"memory"`
	CPU         int    `bson:"cpus"`
	Hostname    string `bson:"hostname"`
}

func (meta *Meta) Valid() error {
	if meta.FilePath == "" {
		return errors.New("vagrant's FilePath metadata is empty")
	}

	return nil
}

func newMetadata(m *stack.Machine) interface{} {
	if m == nil {
		return &Meta{}
	}

	meta := &Meta{
		FilePath: m.Attributes["filePath"],
		Box:      m.Attributes["box"],
		Hostname: m.Attributes["hostname"],
	}

	if n, err := strconv.Atoi(m.Attributes["memory"]); err == nil {
		meta.Memory = n
	}

	if n, err := strconv.Atoi(m.Attributes["cpus"]); err == nil {
		meta.CPU = n
	}

	return meta
}

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	return &Machine{
		BaseMachine: bm,
		api: &vagrantapi.Klient{
			Kite:  bm.Kite,
			Log:   bm.Log.New("vagrantapi"),
			Debug: bm.Debug,
		},
	}, nil
}

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	if bs.TunnelURL == "" {
		return nil, errors.New("no tunnel URL provided")
	}

	u, err := url.Parse(bs.TunnelURL)
	if err != nil {
		return nil, err
	}

	u.Path = "/kite"

	s := &Stack{
		BaseStack: bs,
		TunnelURL: u,
		api: &vagrantapi.Klient{
			Kite:  bs.Session.Kite,
			Log:   bs.Log.New("vagrantapi"),
			Debug: bs.Debug || bs.TraceID != "",
		},
	}

	bs.Planner.OnDial = s.checkTunnel
	bs.PlanFunc = s.plan

	return s, nil
}
