package vagrant

import (
	"errors"

	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stackplan"

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

// Stack
type Stack struct {
	*provider.BaseStack

	api *vagrantapi.Klient
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

	// BUG(rjeczalik): sockjs when tunnelled gives transport error
	// on closed connection - that's why we use long polling here.
	// When tunnelclient is fixed get rid of it.
	k := kite.New("vagrantapi", "0.0.1")
	k.Config = bs.Session.Kite.Config.Copy()
	k.Config.Transport = config.XHRPolling

	api := &vagrantapi.Klient{
		Kite: k,
		Log:  bs.Log.New("vagrantapi"),
	}

	return &Stack{
		BaseStack: bs,
		api:       api,
	}, nil
}
