package terraformer

import (
	"fmt"
	"koding/kites/terraformer"
	"time"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
)

// Terraformer represents a remote terraformer instance.
type Terraformer struct {
	Client *kite.Client
	kite   *kite.Kite
}

// Options are used to connect to a terraformer kite.
type Options struct {
	Endpoint  string
	SecretKey string
	Kite      *kite.Kite
}

// Connect connects to a remote terraformer instance with the given kite instance.
func Connect(opts *Options) (*Terraformer, error) {
	tfKite := opts.Kite.NewClient(opts.Endpoint)
	tfKite.Auth = &kite.Auth{
		Type: "kloud",
		Key:  opts.SecretKey,
	}

	connected, err := tfKite.DialForever()
	if err != nil {
		return nil, err
	}

	// wait until it's connected
	<-connected

	return &Terraformer{
		kite:   opts.Kite,
		Client: tfKite,
	}, nil
}

func (t *Terraformer) Close() {
	t.Client.Close()
}

func (t *Terraformer) Plan(req *terraformer.TerraformRequest) (*terraform.Plan, error) {
	resp, err := t.Client.Tell("plan", req)
	if err != nil {
		return nil, err
	}

	var plan *terraform.Plan
	if err := resp.Unmarshal(&plan); err != nil {
		return nil, err
	}

	return plan, nil
}

func (t *Terraformer) Apply(req *terraformer.TerraformRequest) (*terraform.State, error) {
	resp, err := t.Client.Tell("apply", req)
	if err != nil {
		return nil, err
	}

	var state *terraform.State
	if err := resp.Unmarshal(&state); err != nil {
		return nil, err
	}

	return state, nil
}

func (t *Terraformer) Destroy(req *terraformer.TerraformRequest) (*terraform.State, error) {
	resp, err := t.Client.Tell("destroy", req)
	if err != nil {
		return nil, err
	}

	var state *terraform.State
	if err := resp.Unmarshal(&state); err != nil {
		return nil, err
	}

	return state, nil
}

// Ping checks if the given terraformer response with "pong" to the "ping" we send.
// A nil error means a successfull pong result.
func (t *Terraformer) Ping() error {
	resp, err := t.Client.TellWithTimeout("kite.ping", 10*time.Second)
	if err != nil {
		return err
	}

	out, err := resp.String()
	if err != nil {
		return err
	}

	if out == "pong" {
		return nil
	}

	return fmt.Errorf("wrong response %s", out)
}
