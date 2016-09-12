package vagrant

import (
	"errors"
	"net/url"
	"time"

	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/utils"
	"koding/klient/tunnel"

	"github.com/fatih/structs"
	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func init() {
	stackplan.MetaFuncs["vagrant"] = func() interface{} { return &VagrantMeta{} }

	stack.Providers["vagrant"] = func(bp *provider.BaseProvider) interface{} {
		return &Provider{
			BaseProvider: bp,
		}
	}
}

var _ stack.Validator = (*VagrantMeta)(nil)

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

	// Credential represents Vagrant credential value.
	//
	// The Meta field is of *VagrantMeta type.
	// The field is set during injecting variables to a template.
	Credential *stackplan.Credential

	// The following fields are set by buildResources method:
	ids        stackplan.KiteMap
	klients    map[string]*stackplan.DialState
	region     string
	hostQuery  string
	credential string

	api *vagrantapi.Klient
	p   *stackplan.Planner
}

func (s *Stack) checkTunnel(c *kite.Client) error {
	resp, err := c.TellWithTimeout("tunnel.info", 2*time.Minute)
	if err != nil {
		return err
	}

	var info tunnel.InfoResponse
	if err := resp.Unmarshal(&info); err != nil {
		return err
	}

	s.Log.Debug("received tunnel.info response: %+v", &info)

	if info.State != tunnel.StateConnected {
		// We do not fail here, as the tunnel can be recovering
		// and we might hit the window when it's not yet done.
		// However we log, to show kloud observed problems with
		// connection.
		s.Log.Warning("%s: want tunnel to be %q, was %q instead", c.ID, tunnel.StateConnected, info.State)

		return nil
	}

	if _, ok := info.Ports["kite"]; !ok {
		// Every klient has its connection to kontrol tunneled, thus
		// tunnel.info should report ports for kite. Warn if there're
		// none to show kloud observed unexpected behavior.
		// However it is not critical though, as we were able to
		// kite.ping the klient, it means the klient may have some
		// other problems (connection with host kite etc.).
		s.Log.Warning("%s: no ports for kite", c.ID)
	}

	return nil
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ stack.StackProvider = (*Provider)(nil)

// Stack
func (p *Provider) Stack(ctx context.Context) (stack.Stacker, error) {
	bs, err := p.BaseStack(ctx)
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

	s := &Stack{
		BaseStack: bs,
		TunnelURL: tunnelURL,
		api:       api,
		p: &stackplan.Planner{
			Provider:     "vagrant",
			ResourceType: "instance",
		},
	}

	s.p.OnDial = s.checkTunnel
	bs.BuildResources = s.buildResources
	bs.WaitResources = s.waitResources
	bs.UpdateResources = s.updateResources

	return s, nil
}
