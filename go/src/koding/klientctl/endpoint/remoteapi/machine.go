package remoteapi

import (
	"koding/remoteapi"
	"koding/remoteapi/models"

	machine "koding/remoteapi/client/j_machine"
)

// ListMachines queries for all machines filtered using the given filter.
func (c *Client) ListMachines(f *Filter) ([]*models.JMachine, error) {
	c.init()

	params := &machine.JMachineSomeParams{}

	if f != nil {
		if err := c.buildFilter(f); err != nil {
			return nil, err
		}

		params.Body = f
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JMachine.JMachineSome(params, nil)
	if err != nil {
		return nil, err
	}

	var machines []*models.JMachine

	if err := remoteapi.Unmarshal(resp.Payload, &machines); err != nil {
		return nil, err
	}

	if len(machines) == 0 {
		return nil, ErrNotFound
	}

	return machines, nil
}
