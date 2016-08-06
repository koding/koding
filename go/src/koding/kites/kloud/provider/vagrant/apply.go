package vagrant

import (
	"github.com/hashicorp/terraform/terraform"

	"golang.org/x/net/context"
)

func (s *Stack) buildResources() (err error) {
	s.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	s.hostQuery, s.ids, err = s.InjectVagrantData()

	return err
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

	s.Log.Debug("Machines from state: %+v", machines)
	s.Log.Debug("Build data kiteIDS: %+v", s.ids)

	return s.updateMachines(machines, s.Builder.Machines)
}
