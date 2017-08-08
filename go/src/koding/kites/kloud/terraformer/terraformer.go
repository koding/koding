package terraformer

import (
	"fmt"
	"time"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
)

// TerraformRequest is a helper struct for terraformer kite requests.
//
// Copied from kites/terraformer/terraformer.go to avoid dependency
// on the terraformer package.
type TerraformRequest struct {
	Content   string
	Variables map[string]interface{}
	ContentID string
	TraceID   string
}

// Terraformer represents a remote terraformer instance.
type Terraformer struct {
	Client *kite.Client
	kite   *kite.Kite
}

// Connect connects to a remote terraformer instance with the given kite instance.
func Connect(endpoint, secretKey string, k *kite.Kite) (*Terraformer, error) {
	tfKite := k.NewClient(endpoint)
	tfKite.Auth = &kite.Auth{
		Type: "kloud",
		Key:  secretKey,
	}

	connected, err := tfKite.DialForever()
	if err != nil {
		return nil, err
	}

	// wait until it's connected
	<-connected

	return &Terraformer{
		kite:   k,
		Client: tfKite,
	}, nil
}

func (t *Terraformer) Close() {
	t.Client.Close()
}

func (t *Terraformer) Plan(req *TerraformRequest) (*terraform.Plan, error) {
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

func (t *Terraformer) Apply(req *TerraformRequest) (*terraform.State, error) {
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

func (t *Terraformer) Destroy(req *TerraformRequest) (*terraform.State, error) {
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
// A nil error means a successful pong result.
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
