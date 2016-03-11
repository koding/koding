package vagrant

import (
	"errors"
	"net/url"

	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/utils"

	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"golang.org/x/net/context"
)

func init() {
	stackplan.MetaFuncs["vagrant"] = func() interface{} { return &VagrantMeta{} }
}

var _ kloud.Validator = (*VagrantMeta)(nil)

// VagrantMeta represents jCredentialDatas.meta for "vagrant" provider.
type VagrantMeta struct {
	QueryString string `json:"queryString" bson:"queryString" hcl:"queryString"`
	Memory      int    `json:"memory" bson:"memory" hcl:"memory"`
	CPU         int    `json:"cpus" bson:"cpus" hcl:"cpus"`
	Box         string `json:"box" bson:"box" hcl:"box"`
}

// Valid implements the kloud.Validator interface.
func (meta *VagrantMeta) Valid() error {
	if meta.QueryString == "" {
		return errors.New("vagrant meta: query string is empty")
	}
	meta.QueryString = utils.QueryString(meta.QueryString)
	return nil
}

// SetDefaults sets default values for vagrant credential metadata.
//
// TODO(rjeczalik): Compatibility code, remove when defaults are set elsewhere.
func (meta *VagrantMeta) SetDefaults() (updated bool) {
	if !structs.HasZero(meta) {
		return false
	}
	if meta.Memory == 0 {
		meta.Memory = 2048
	}
	if meta.CPU == 0 {
		meta.CPU = 2
	}
	if meta.Box == "" {
		meta.Box = "ubuntu/trusty64"
	}
	return true
}

// Stack provides an implementation for the kloud.Stacker interface.
type Stack struct {
	*provider.BaseStack

	// TunnelURL for klient connection inside vagrant boxes.
	TunnelURL *url.URL

	api *vagrantapi.Klient
	p   *stackplan.Planner
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ kloud.StackProvider = (*Provider)(nil)

// Stack
func (p *Provider) Stack(ctx context.Context) (kloud.Stacker, error) {
	bs, err := provider.NewBaseStack(ctx, p.Log)
	if err != nil {
		return nil, err
	}

	tunnelURL, err := p.tunnelURL()
	if err != nil {
		return nil, err
	}

	api := &vagrantapi.Klient{
		Kite:  bs.Session.Kite,
		Log:   bs.Log.New("vagrantapi"),
		Debug: p.Debug || bs.TraceID != "",
	}

	return &Stack{
		BaseStack: bs,
		TunnelURL: tunnelURL,
		api:       api,
		p: &stackplan.Planner{
			Provider:     "vagrant",
			ResourceType: "instance",
		},
	}, nil
}

func newKite(k *kite.Kite) *kite.Kite {
	cfg := k.Config.Copy()
	cfg.Transport = config.XHRPolling
	kCopy := kite.New(kloud.NAME, kloud.VERSION)
	kCopy.Config = cfg
	return kCopy
}
