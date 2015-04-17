package main

import (
	"testing"

	"koding/kites/terraformer"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/multiconfig"
)

var variables = map[string]string{
	"aws_access_key":   "AKIAJTDKW5IFUUIWVNAA",
	"aws_region":       "sa-east-1",
	"aws_secret_key":   "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",
	"cidr_block":       "10.0.0.0/16",
	"environment_name": "kodingterraformtest",
}

func withKite(t *testing.T, f func(k *kite.Kite) error) {
	conf := &terraformer.Config{}

	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	c := createContex()
	k := newKite(conf, c)
	k.Config.DisableAuthentication = true
	go k.Run()
	defer k.Close()
	<-k.ServerReadyNotify()

	err := f(k)
	if err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

func TestApply(t *testing.T) {
	local := kite.New("testing", "1.0.0")

	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		req := terraformer.TerraformRequest{
			Content:   SampleTF,
			Variables: variables,
		}

		response, err := tfr.Tell("plan", req)
		if err != nil {
			return err
		}

		res := terraform.Plan{}
		if err := response.Unmarshal(&res); err != nil {
			return err
		}

		return nil
	})

}
