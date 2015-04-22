package terraformer

import (
	"bytes"
	"koding/kites/terraformer/kodingcontext"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
)

var (
	Name    = "terraformer"
	Version = "0.0.1"
)

type Terraformer struct {
	Log logging.Logger

	Metrics *metrics.DogStatsD

	// Enable debug mode
	Debug bool

	Context *kodingcontext.Context
}

type TerraformRequest struct {
	Content   string
	Variables map[string]string
}

func New() *Terraformer {
	return &Terraformer{}
}

func (t *Terraformer) Apply(r *kite.Request) (interface{}, error) {
	c := t.Context.Clone()
	defer c.Close()

	ctx, err := t.context(c, r, false)
	if err != nil {
		return nil, err
	}

	state, err := ctx.Apply()
	if err != nil {
		return nil, err
	}

	return state, nil
}

func (t *Terraformer) Destroy(r *kite.Request) (interface{}, error) {
	c := t.Context.Clone()
	defer c.Close()

	//
	// plan first with destroy option
	//
	plan, err := t.plan(c, r, true)
	if err != nil {
		return nil, err
	}

	//
	// create terraform context options from plan
	//
	copts := c.TerraformContextOptsWithPlan(plan)

	copts.Destroy = true // this is the key point

	// create terraform context with its options
	ctx := terraform.NewContext(copts)

	//
	// apply the change
	//
	state, err := ctx.Apply()
	if err != nil {
		return nil, err
	}

	return state, nil
}

func (t *Terraformer) Plan(r *kite.Request) (interface{}, error) {
	c := t.Context.Clone()
	defer c.Close()

	plan, err := t.plan(c, r, false)
	if err != nil {
		return nil, err
	}

	return plan, nil
}

func (t *Terraformer) context(
	c *kodingcontext.Context,
	r *kite.Request,
	destroy bool,
) (*terraform.Context, error) {
	// get the plan
	plan, err := t.plan(c, r, destroy)
	if err != nil {
		return nil, err
	}

	// create terraform context options from plan
	copts := c.TerraformContextOptsWithPlan(plan)

	// create terraform context with its options
	ctx := terraform.NewContext(copts)

	return ctx, nil
}

func (t *Terraformer) plan(
	c *kodingcontext.Context,
	r *kite.Request,
	destroy bool,
) (*terraform.Plan, error) {
	args := TerraformRequest{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	c.Variables = args.Variables

	plan, err := c.Plan(
		bytes.NewBufferString(args.Content),
		destroy,
	)
	if err != nil {
		return nil, err
	}

	return plan, nil
}
