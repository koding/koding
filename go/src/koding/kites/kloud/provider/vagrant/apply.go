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

	s.urls, err = s.p.CheckKlients(ctx, s.ids)

	return err
}

func (s *Stack) updateResources(state *terraform.State) error {
	output, err := s.p.MachinesFromState(state)
	if err != nil {
		return err
	}

	s.Log.Debug("Machines from state: %+v", output)
	s.Log.Debug("Build data kiteIDS: %+v", s.ids)

	output.AppendQueryString(s.ids)
	output.AppendHostQueryString(s.hostQuery)
	output.AppendRegisterURL(s.urls)

	return s.updateMachines(output, s.Builder.Machines)
}
