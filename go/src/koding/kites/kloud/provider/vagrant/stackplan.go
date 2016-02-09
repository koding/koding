package vagrant

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/machinestate"
	puser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/stackplan"

	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

// VagrantResource represents vagrant_instance Terraform resource.
type VagrantResource struct {
	Build map[string]map[string]interface{} `hcl:"vagrant_instance"`
}

func (s *Stack) updateCredential(cred *stackplan.Credential) error {
	meta := cred.Meta.(*VagrantMeta)
	if !meta.SetDefaults() {
		return nil
	}
	return modelhelper.UpdateCredentialData(cred.Identifier, bson.M{
		"$set": bson.M{
			"meta.memory": meta.Memory,
			"meta.cpus":   meta.CPU,
			"meta.box":    meta.Box,
		},
	})
}

// InjectVagrantData sets default properties for vagrant_instance Terraform template.
//
// TODO(rjeczalik): move out hostQueryString outside this method.
func (s *Stack) InjectVagrantData(ctx context.Context, username string) (string, stackplan.KiteMap, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return "", nil, errors.New("session context is not passed")
	}

	// TODO(rjeczalik): add ByProvider to stackplan.Credentials
	var cred *stackplan.Credential
	for _, c := range s.Builder.Credentials {
		if c.Provider == "vagrant" {
			cred = c
			break
		}
	}

	if cred == nil {
		return "", nil, errors.New("vagrant credential not found")
	}

	if err := s.updateCredential(cred); err != nil {
		return "", nil, err
	}

	t := s.Builder.Template

	s.Log.Debug("Injecting vagrant credentials: %# v", cred.Meta)

	if err := t.InjectVariables(cred.Provider, cred.Meta); err != nil {
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

	for resourceName, box := range res.Build {
		kiteID := uuid.NewV4().String()

		kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteID)
		if err != nil {
			return "", nil, err
		}

		klientURL, err := sess.Userdata.LookupKlientURL()
		if err != nil {
			return "", nil, err
		}

		// set registerURL if not provided via template
		registerURL := s.tunnelUniqueURL(username)
		if r, ok := box["registerURL"].(string); ok {
			registerURL = r
		} else {
			box["registerURL"] = registerURL
		}

		// set kontrolURL if not provided via template
		kontrolURL := sess.Userdata.Keycreator.KontrolURL
		if k, ok := box["kontrolURL"].(string); ok {
			kontrolURL = k
		} else {
			box["kontrolURL"] = kontrolURL
		}

		// set default filePath to relative <stackdir>/<boxname>; for
		// default configured klient it resolves to ~/.vagrant.d/<stackdir>/<boxname>
		if _, ok := box["filePath"]; !ok {
			box["filePath"] = "${var.koding_group_slug}/" + resourceName
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

		data := puser.Value{
			Username:        username,
			Groups:          []string{"sudo"},
			Hostname:        username, // no typo here. hostname = username
			KiteKey:         kiteKey,
			LatestKlientURL: klientURL,
			RegisterURL:     registerURL,
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

		encoded := base64.StdEncoding.EncodeToString(val)
		box["provisionData"] = encoded
		kiteIDs[resourceName] = kiteID
		res.Build[resourceName] = box
	}

	t.Resource["vagrant_instance"] = res.Build

	if err := t.Flush(); err != nil {
		return "", nil, err
	}

	return cred.Meta.(*VagrantMeta).QueryString, kiteIDs, nil
}

func (s *Stack) machinesFromTemplate(t *stackplan.Template, hostQueryString string) (*stackplan.Machines, error) {
	var res VagrantResource
	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	out := &stackplan.Machines{
		Machines: make([]stackplan.Machine, 0, len(res.Build)),
	}

	for label, box := range res.Build {
		m := stackplan.Machine{
			Provider:        "vagrant",
			Label:           label,
			HostQueryString: hostQueryString,
			Attributes:      map[string]string{},
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

		out.Machines = append(out.Machines, m)
	}

	return out, nil
}

func (s *Stack) updateMachines(ctx context.Context, data *stackplan.Machines, jMachines []*models.Machine) error {
	for _, machine := range jMachines {
		label := machine.Label
		if l, ok := machine.Meta["assignedLabel"]; ok {
			if ll, ok := l.(string); ok {
				label = ll
			}
		}

		s.Log.Debug("Updating machine with %q label and %q provider", label, machine.Provider)

		tf, err := data.WithLabel(label)
		if err != nil {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", label)
		}

		if tf.Provider == "vagrant" {
			if err := updateVagrant(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		}
	}

	return nil
}

func updateVagrant(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
	return modelhelper.UpdateMachine(machineId, bson.M{"$set": bson.M{
		"provider":             tf.Provider,
		"meta.hostQueryString": tf.HostQueryString,
		"queryString":          tf.QueryString,
		"ipAddress":            tf.Attributes["ipAddress"],
		"meta.filePath":        tf.Attributes["filePath"],
		"meta.memory":          tf.Attributes["memory"],
		"meta.cpus":            tf.Attributes["cpus"],
		"meta.box":             tf.Attributes["box"],
		"meta.hostname":        tf.Attributes["hostname"],
		"meta.klientHostURL":   tf.Attributes["klientHostURL"],
		"meta.klientGuestURL":  tf.Attributes["klientGuestURL"],
		"status.state":         machinestate.Running.String(),
		"status.modifiedAt":    time.Now().UTC(),
		"status.reason":        "Created with kloud.apply",
	}})
}
