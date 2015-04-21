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

	plan, err := t.plan(c, r)
	if err != nil {
		return nil, err
	}

	copts := c.TerraformContextOptsWithPlan(plan)
	ctx := terraform.NewContext(copts)
	state, err := ctx.Apply()
	if err != nil {
		return nil, err
	}

	return state, nil
}

func (t *Terraformer) Destroy(r *kite.Request) (interface{}, error) {
	c := t.Context.Clone()
	defer c.Close()

	return nil, nil
}

func (t *Terraformer) Plan(r *kite.Request) (interface{}, error) {
	c := t.Context.Clone()
	defer c.Close()

	plan, err := t.plan(c, r)
	if err != nil {
		return nil, err
	}

	return plan, nil
}

func (t *Terraformer) plan(c *kodingcontext.Context, r *kite.Request) (*terraform.Plan, error) {
	args := TerraformRequest{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	c.Variables = args.Variables

	plan, err := c.Plan(bytes.NewBufferString(args.Content))
	if err != nil {
		return nil, err
	}

	return plan, nil
}
