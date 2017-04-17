package vagrant

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"time"

	"koding/kites/kloud/api/vagrantapi"
	puser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/utils"
	"koding/klient/tunnel"

	"github.com/koding/kite"
)

// VagrantResource represents vagrant_instance Terraform resource.
type VagrantResource struct {
	Build map[string]map[string]interface{} `hcl:"vagrant_instance"`
}

type Tunnel struct {
	Name    string
	KiteURL string
}

// Stack provides an implementation for the kloud.Stacker interface.
type Stack struct {
	*provider.BaseStack

	// TunnelURL for klient connection inside vagrant boxes.
	TunnelURL *url.URL

	api *vagrantapi.Klient
}

var (
	_ provider.Stack = (*Stack)(nil)
	_ stack.Stacker  = (*Stack)(nil)
)

func (s *Stack) VerifyCredential(c *stack.Credential) error {
	version, err := s.api.Version(c.Credential.(*Cred).QueryString)
	if err != nil {
		return err
	}

	if version == "" {
		return errors.New("invalid version empty response")
	}

	return nil
}

func (s *Stack) BootstrapTemplates(*stack.Credential) ([]*stack.Template, error) {
	return make([]*stack.Template, 0), nil
}

// InjectVagrantData sets default properties for vagrant_instance Terraform template.
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template
	cred := c.Credential.(*Cred)

	var res VagrantResource

	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	if len(res.Build) == 0 {
		return nil, errors.New("no vagrant instances specified")
	}

	uids := s.Builder.MachineUIDs()

	s.Log.Debug("machine uids (%d): %v", len(uids), uids)

	klientURL, err := s.Session.Userdata.LookupKlientURL()
	if err != nil {
		return nil, err
	}

	// queryString is taken from jCredentialData.meta.queryString,
	// for debugging purposes it can be overwritten in the template,
	// however if template has multiple machines, all of them
	// are required to overwrite the queryString to the same value
	// to match current implementation of terraformplugins/vagrant
	// provider.
	//
	// Otherwise we fail early to show problem with the template.
	var queryString string
	for resourceName, box := range res.Build {
		kiteKey, err := s.BuildKiteKey(resourceName, s.Req.Username)
		if err != nil {
			return nil, err
		}

		// set kontrolURL if not provided via template
		kontrolURL := s.Session.Userdata.Keycreator.KontrolURL
		if k, ok := box["kontrolURL"].(string); ok {
			kontrolURL = k
		} else {
			box["kontrolURL"] = kontrolURL
		}

		if q, ok := box["queryString"].(string); ok {
			q, err := utils.QueryString(q)
			if err != nil {
				return nil, fmt.Errorf("%s: error reading queryString: %s", resourceName, err)
			}
			if queryString != "" && queryString != q {
				return nil, fmt.Errorf("mismatched queryString provided for multiple instances; want %q, got %q", queryString, q)
			}
			queryString = q
		} else {
			box["queryString"] = "${var.vagrant_queryString}"
			queryString = cred.QueryString
		}

		// set default filePath to relative <stackdir>/<boxname>; for
		// default configured klient it resolves to ~/.vagrant.d/<stackdir>/<boxname>
		if _, ok := box["filePath"]; !ok {
			uid, ok := uids[resourceName]
			if !ok {
				// For Plan call we return random uid as it won't be returned
				// as a part of meta; the filePath is inserted into meta by
				// the apply method.
				uid = resourceName + "-" + utils.RandString(6)
			}
			box["filePath"] = "koding/${var.koding_group_slug}/" + uid
		}

		// set default CPU number
		if _, ok := box["cpus"]; !ok {
			box["cpus"] = "${var.vagrant_cpus}"
		}

		// set default RAM in MiB
		if _, ok := box["memory"]; !ok {
			box["memory"] = "${var.vagrant_memory}"
		}

		// set default box type
		if _, ok := box["box"]; !ok {
			box["box"] = "${var.vagrant_box}"
		}

		var ports []interface{}

		switch p := box["forwarded_ports"].(type) {
		case []interface{}:
			ports = p
		case []map[string]interface{}:
			ports = make([]interface{}, len(p))

			for i := range p {
				ports[i] = p[i]
			}
		}

		// klient kite port
		kitePort := &vagrantapi.ForwardedPort{
			HostPort:  2200,
			GuestPort: 56789,
		}

		// tlsproxy port
		kitesPort := &vagrantapi.ForwardedPort{
			HostPort:  2201,
			GuestPort: 56790,
		}

		ports = append(ports, kitePort, kitesPort)

		box["forwarded_ports"] = ports
		box["username"] = s.Req.Username

		tunnel := s.newTunnel(resourceName)

		if b, ok := box["debug"].(bool); ok && b {
			s.Debug = true
		}

		data := puser.Value{
			Username:        s.Req.Username,
			Groups:          []string{"sudo"},
			Hostname:        s.Req.Username, // no typo here. hostname = username
			KiteKey:         kiteKey,
			LatestKlientURL: klientURL,
			TunnelName:      tunnel.Name,
			TunnelKiteURL:   tunnel.KiteURL,
			KontrolURL:      kontrolURL,
		}

		// pass the values as a JSON encoded as base64. Our script will decode
		// and unmarshall and use it inside the Vagrant box
		val, err := json.Marshal(&data)
		if err != nil {
			return nil, err
		}

		// Compressing the provision data isn't doing any serious optimizations,
		// it's just here so the debug output does not take half a screen.
		//
		// The provisionclient handles both compressed and uncompressed JSONs.
		var buf bytes.Buffer
		if cw, err := gzip.NewWriterLevel(&buf, 9); err == nil {
			if _, err = io.Copy(cw, bytes.NewReader(val)); err == nil && cw.Close() == nil {
				s.Log.Debug("using compressed provision data: %d vs %d", len(val), len(buf.Bytes()))

				val = buf.Bytes()
			}
		}

		box["provisionData"] = base64.StdEncoding.EncodeToString(val)
		res.Build[resourceName] = box
	}

	t.Resource["vagrant_instance"] = res.Build

	if err := t.Flush(); err != nil {
		return nil, err
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: content,
	}, nil
}

func (s *Stack) machinesFromTemplate(t *provider.Template) (stack.Machines, error) {
	var res VagrantResource
	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	machines := make(stack.Machines, len(res.Build))

	for label, box := range res.Build {
		m := &stack.Machine{
			Provider:   "vagrant",
			Label:      label,
			Attributes: make(map[string]string),
		}

		if cpus, ok := box["cpus"].(string); ok && !provider.IsVariable(cpus) {
			m.Attributes["cpus"] = cpus
		}
		if mem, ok := box["memory"].(string); ok && !provider.IsVariable(mem) {
			m.Attributes["memory"] = mem
		}
		if typ, ok := box["box"].(string); ok && !provider.IsVariable(typ) {
			m.Attributes["box"] = typ
		}

		if _, ok := machines[label]; ok {
			return nil, errors.New("duplicate instance labels: " + label)
		}

		machines[label] = m
	}

	return machines, nil
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

func (s *Stack) newTunnel(resourceName string) *Tunnel {
	t := &Tunnel{
		Name:    utils.RandString(12),
		KiteURL: s.TunnelURL.String(),
	}

	if m, ok := s.Builder.Machines[resourceName]; ok {
		t.Name = m.Uid
	}

	return t
}

func (s *Stack) plan() (stack.Machines, error) {
	return s.machinesFromTemplate(s.Builder.Template)
}
