package vagrant

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
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

// VagrantResource
type VagrantResource struct {
	Build map[string]map[string]interface{} `hcl:"vagrantkite_build`
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

// InjectVagrantData
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

	if err := s.Builder.Template.InjectVariables(cred.Provider, cred.Meta); err != nil {
		return "", nil, err
	}

	hostQueryString := cred.Meta.(*VagrantMeta).QueryString

	var res VagrantResource

	if err := s.Builder.Template.DecodeResource(&res); err != nil {
		return "", nil, err
	}

	if len(res.Build) == 0 {
		s.Log.Debug("No Vagrant build available")
		return hostQueryString, nil, nil
	}

	kiteIDs := make(stackplan.KiteMap)

	for resourceName, box := range res.Build {
		kiteID := uuid.NewV4().String()

		kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteID)
		if err != nil {
			return "", nil, err
		}

		klientURL, err := sess.Userdata.Bucket.LatestDeb()
		if err != nil {
			return "", nil, err
		}
		klientURL = sess.Userdata.Bucket.URL(klientURL)

		// get the registerURL if passed via template
		var registerURL string
		if r, ok := box["registerURL"]; ok {
			if ru, ok := r.(string); ok {
				registerURL = ru
			}
		}

		// get the kontrolURL if passed via template
		var kontrolURL string
		if k, ok := box["kontrolURL"]; ok {
			if ku, ok := k.(string); ok {
				kontrolURL = ku
			}
		}

		if s, ok := box["queryString"].(string); !ok {
			box["queryString"] = "${var.vagrant_queryString}"
		} else {
			hostQueryString = s
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

		kiteIDs[resourceName] = kiteID
		encoded := base64.StdEncoding.EncodeToString(val)
		box["provisionData"] = encoded
		res.Build[resourceName] = box
	}

	s.Builder.Template.Resource["vagrantkite_build"] = res.Build

	if err := s.Builder.Template.Flush(); err != nil {
		return "", nil, err
	}

	return hostQueryString, kiteIDs, nil
}

func (s *Stack) machinesFromTemplate(t *stackplan.Template, hostQueryString string) (*stackplan.Machines, error) {
	var res VagrantResource
	if err := t.DecodeResource(&s); err != nil {
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

		if tf.Provider == "vagrantkite" {
			if err := updateVagrantKite(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		}
	}

	return nil
}

func updateVagrantKite(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
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
