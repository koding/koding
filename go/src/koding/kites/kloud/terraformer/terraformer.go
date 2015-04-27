package terraformer

import (
	"fmt"
	"koding/kites/terraformer"
	"koding/kites/terraformer/secretkey"
	"time"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
)

// Terraformer represents a remote terraformer instance
type Terraformer struct {
	Client *kite.Client
	kite   *kite.Kite
}

// Connect connects to a remote terraformer instance with the given kite instance
func Connect(k *kite.Kite) (*Terraformer, error) {
	terraformerURL := "http://127.0.0.1:2300/kite"

	tfKite := k.NewClient(terraformerURL)
	tfKite.Auth = &kite.Auth{
		Type: "kloud",
		Key:  secretkey.TerraformSecretKey,
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

func (t *Terraformer) Plan(context string) (*terraform.Plan, error) {
	req := terraformer.TerraformRequest{
		Content: context,
	}

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

func (t *Terraformer) Apply(context string) (*terraform.Plan, error) {
	req := terraformer.TerraformRequest{
		Content: context,
	}

	resp, err := t.Client.Tell("apply", req)
	if err != nil {
		return nil, err
	}

	var plan *terraform.Plan
	if err := resp.Unmarshal(&plan); err != nil {
		return nil, err
	}

	return plan, nil
}

func (t *Terraformer) Destroy() error {
	return nil
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
