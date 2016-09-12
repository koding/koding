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
	"strconv"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/vagrantapi"
	puser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/utils"

	"github.com/satori/go.uuid"
	"gopkg.in/mgo.v2/bson"
)

// VagrantResource represents vagrant_instance Terraform resource.
type VagrantResource struct {
	Build map[string]map[string]interface{} `hcl:"vagrant_instance"`
}

func (s *Stack) updateCredential(cred *stackplan.Credential) {
	meta := cred.Meta.(*VagrantMeta)
	meta.SetDefaults()
}

type Tunnel struct {
	Name    string
	KiteURL string
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

// InjectVagrantData sets default properties for vagrant_instance Terraform template.
//
// TODO(rjeczalik): move out hostQueryString outside this method.
func (s *Stack) InjectVagrantData() (string, stackplan.KiteMap, error) {
	// TODO(rjeczalik): add ByProvider to stackplan.Credentials
	for _, c := range s.Builder.Credentials {
		if c.Provider == "vagrant" {
			s.Credential = c
			break
		}
	}

	if s.Credential == nil {
		return "", nil, errors.New("vagrant credential not found")
	}

	s.updateCredential(s.Credential)

	t := s.Builder.Template
	meta := s.Credential.Meta.(*VagrantMeta)

	s.Log.Debug("Injecting vagrant credentials: %# v", meta)

	if err := t.InjectVariables(s.Credential.Provider, s.Credential.Meta); err != nil {
		return "", nil, err
	}

	var res VagrantResource

	if err := t.DecodeResource(&res); err != nil {
		return "", nil, err
	}

	if len(res.Build) == 0 {
		return "", nil, errors.New("no vagrant instances specified")
	}

	kiteIDs := make(stackplan.KiteMap)

	uids := s.Builder.MachineUIDs()

	s.Log.Debug("machine uids (%d): %v", len(uids), uids)

	klientURL, err := s.Session.Userdata.LookupKlientURL()
	if err != nil {
		return "", nil, err
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
		kiteID := uuid.NewV4().String()

		kiteKey, err := s.Session.Userdata.Keycreator.Create(s.Req.Username, kiteID)
		if err != nil {
			return "", nil, err
		}

		// set kontrolURL if not provided via template
		kontrolURL := s.Session.Userdata.Keycreator.KontrolURL
		if k, ok := box["kontrolURL"].(string); ok {
			kontrolURL = k
		} else {
			box["kontrolURL"] = kontrolURL
		}

		if q, ok := box["queryString"].(string); ok {
			q = utils.QueryString(q)
			if queryString != "" && queryString != q {
				return "", nil, fmt.Errorf("mismatched queryString provided for multiple instances; want %q, got %q", queryString, q)
			}
			queryString = q
		} else {
			box["queryString"] = "${var.vagrant_queryString}"
			queryString = meta.QueryString
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

		s.Builder.InterpolateField(box, resourceName, "user_data")

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

		// pass the values as a JSON encoded as bae64. Our script will decode
		// and unmarshall and use it inside the Vagrant box
		val, err := json.Marshal(&data)
		if err != nil {
			return "", nil, err
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
		kiteIDs[resourceName] = kiteID
		res.Build[resourceName] = box
	}

	t.Resource["vagrant_instance"] = res.Build

	if err := t.Flush(); err != nil {
		return "", nil, err
	}

	return queryString, kiteIDs, nil
}

func (s *Stack) machinesFromTemplate(t *stackplan.Template) (stackplan.Machines, error) {
	var res VagrantResource
	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	machines := make(stackplan.Machines, len(res.Build))

	for label, box := range res.Build {
		m := &stackplan.Machine{
			Provider:   "vagrant",
			Label:      label,
			Attributes: make(map[string]string),
		}

		if cpus, ok := box["cpus"].(string); ok && !stackplan.IsVariable(cpus) {
			m.Attributes["cpus"] = cpus
		}
		if mem, ok := box["memory"].(string); ok && !stackplan.IsVariable(mem) {
			m.Attributes["memory"] = mem
		}
		if typ, ok := box["box"].(string); ok && !stackplan.IsVariable(typ) {
			m.Attributes["box"] = typ
		}

		if _, ok := machines[label]; ok {
			return nil, errors.New("duplicate instance labels: " + label)
		}

		machines[label] = m
	}

	return machines, nil
}

func (s *Stack) updateMachines(machines stackplan.Machines, jMachines map[string]*models.Machine) error {
	for label, machine := range jMachines {
		s.Log.Debug("Updating machine with %q label and %q provider", label, machine.Provider)

		tf, ok := machines[label]
		if !ok {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", label)
		}

		if tf.Provider == "vagrant" {
			if err := updateVagrant(tf, machine.ObjectId, s.Credential.Identifier); err != nil {
				return stackplan.ResError(err, "jMachine")
			}
		}
	}

	return nil
}

func updateVagrant(tf *stackplan.Machine, machineId bson.ObjectId, credential string) error {
	machine := bson.M{
		"provider":           tf.Provider,
		"queryString":        tf.QueryString,
		"credential":         credential,
		"ipAddress":          tf.Attributes["ipAddress"],
		"meta.filePath":      tf.Attributes["filePath"],
		"meta.box":           tf.Attributes["box"],
		"meta.hostname":      tf.Attributes["hostname"],
		"meta.klientHostURL": tf.Attributes["klientHostURL"],
		"status.modifiedAt":  time.Now().UTC(),
		"status.state":       tf.State.String(),
		"status.reason":      tf.StateReason,
	}

	if u, err := url.Parse(tf.RegisterURL); tf.RegisterURL != "" && err == nil {
		u.Path = "/klient/kite"
		machine["meta.klientGuestURL"] = u.String()
		machine["domain"] = u.Host
	}

	if n, err := strconv.Atoi(tf.Attributes["memory"]); err == nil {
		machine["meta.memory"] = n
	}

	if n, err := strconv.Atoi(tf.Attributes["cpus"]); err == nil {
		machine["meta.cpus"] = n
	}

	return modelhelper.UpdateMachine(machineId, bson.M{"$set": machine})
}
