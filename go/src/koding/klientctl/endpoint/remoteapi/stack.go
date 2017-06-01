package remoteapi

import (
	"koding/remoteapi"
	"koding/remoteapi/models"

	computestack "koding/remoteapi/client/j_compute_stack"
)

// ListStacks gives all stacks, filtered by the given f filter.
func (c *Client) ListStacks(f *Filter) ([]*models.JComputeStack, error) {
	c.init()

	params := &computestack.JComputeStackSomeParams{}

	if f != nil {
		if err := c.buildFilter(f); err != nil {
			return nil, err
		}

		params.Body = f
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JComputeStack.JComputeStackSome(params, nil)
	if err != nil {
		return nil, err
	}

	var stacks []*models.JComputeStack

	if err := remoteapi.Unmarshal(resp.Payload, &stacks); err != nil {
		return nil, err
	}

	if len(stacks) == 0 {
		return nil, ErrNotFound
	}

	return stacks, nil
}

// Stack looks up a single compute stack with the given filter.
func (c *Client) Stack(f *Filter) (*models.JComputeStack, error) {
	c.init()

	params := &computestack.JComputeStackOneParams{}

	if f != nil {
		if err := c.buildFilter(f); err != nil {
			return nil, err
		}

		params.Body = f
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JComputeStack.JComputeStackOne(params, nil)
	if err != nil {
		return nil, err
	}

	var stack models.JComputeStack

	if err := remoteapi.Unmarshal(resp.Payload, &stack); err != nil {
		return nil, err
	}

	if stack.ID == "" {
		return nil, ErrNotFound
	}

	return &stack, nil
}

// ListStacks gives all stacks, filtered by the given f filter.
//
// The functions uses DefaultClient.
func ListStacks(f *Filter) ([]*models.JComputeStack, error) {
	return DefaultClient.ListStacks(f)
}
