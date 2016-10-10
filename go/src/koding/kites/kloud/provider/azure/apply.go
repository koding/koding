package azure

import (
	"fmt"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stackplan"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

func (s *Stack) buildResources() error {
	kiteIDs, err := s.InjectAzureData()
	if err != nil {
		return err
	}

	s.ids = kiteIDs

	return nil
}

func (s *Stack) waitResources(ctx context.Context) (err error) {
	s.Log.Debug("Checking total '%d' klients", len(s.ids))

	s.klients, err = s.p.DialKlients(ctx, s.ids)

	return err
}

func (s *Stack) updateResources(state *terraform.State) error {
	machines, err := s.p.MachinesFromState(state, s.klients)
	if err != nil {
		return err
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
	return modelhelper.UpdateMachine(id, bson.M{"$set": bson.M{
		"credential":          s.c.Identifier,
		"provider":            m.Provider,
		"queryString":         m.QueryString,
		"ipAddress":           m.Attributes["vip_address"],
		"meta.instanceId":     m.Attributes["id"],
		"meta.instance_type":  m.Attributes["size"],
		"meta.hostedSericeId": m.Attributes["hosted_service_name"],
		"meta.location":       s.Cred().Location,
		"status.modifiedAt":   now,
		"status.state":        m.State,
		"status.reason":       m.StateReason,
	}})
}
