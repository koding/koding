package awsprovider

import (
	"fmt"
	"strconv"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stackplan"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

func (s *Stack) buildResources() error {
	for _, cred := range s.Builder.Credentials {
		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		meta := cred.Meta.(*AwsMeta)
		if meta.Region == "" {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		// check if this a second round and it's using a different region, we
		// shouldn't allow it.
		if s.region != "" && s.region != meta.Region {
			return fmt.Errorf("multiple credentials with multiple regions detected: %s and %s. Aborting",
				s.region, meta.Region)
		}

		s.region = meta.Region
		s.credential = cred.Identifier

		if err := s.SetAwsRegion(s.region); err != nil {
			return err
		}
	}

	kiteIDs, err := s.InjectAWSData()
	if err != nil {
		return err
	}

	s.ids = kiteIDs

	return nil
}

func (s *Stack) waitResources(ctx context.Context) (err error) {
	s.Log.Debug("Checking total '%d' klients", len(s.ids))

	s.urls, err = s.p.CheckKlients(ctx, s.ids)

	return err
}

func (s *Stack) updateResources(state *terraform.State) error {
	output, err := s.p.MachinesFromState(state)
	if err != nil {
		return err
	}

	output.AppendRegion(s.region)
	output.AppendQueryString(s.ids)
	output.AppendRegisterURL(s.urls)

	machines := make(map[string]*stackplan.Machine, len(output.Machines))

	for _, m := range output.Machines {
		m := m // copy m to not have values in machines map point to the same m

		machines[m.Label] = &m
	}

	now := time.Now().UTC()

	for label, m := range s.Builder.Machines {
		machine, ok := machines[label]
		if !ok {
			err = multierror.Append(err, fmt.Errorf("machine %q does not exist in terraform state file", label))
			continue
		}

		if machine.Provider != "aws" {
			continue
		}

		if e := s.updateMachine(m.ObjectId, machine, now); e != nil {
			err = multierror.Append(err, e)
			continue
		}
	}

	return err
}

func (s *Stack) updateMachine(id bson.ObjectId, m *stackplan.Machine, now time.Time) error {
	size, err := strconv.Atoi(m.Attributes["root_block_device.0.volume_size"])
	if err != nil {
		return err
	}

	return modelhelper.UpdateMachine(id, bson.M{"$set": bson.M{
		"credential":         s.credential,
		"provider":           m.Provider,
		"meta.region":        m.Region,
		"queryString":        m.QueryString,
		"ipAddress":          m.Attributes["public_ip"],
		"meta.instanceId":    m.Attributes["id"],
		"meta.instance_type": m.Attributes["instance_type"],
		"meta.source_ami":    m.Attributes["ami"],
		"meta.storage_size":  size,
		"status.state":       machinestate.Running.String(),
		"status.modifiedAt":  now,
		"status.reason":      "Created with kloud.apply",
	}})
}
