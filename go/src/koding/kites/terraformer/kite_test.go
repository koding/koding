package terraformer

import (
	"fmt"
	"io/ioutil"
	"log"
	"testing"

	"koding/kites/common"

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
	conf := &Config{}
	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	// enable test mode
	conf.Test = true

	if !conf.Debug {
		// hashicorp.terraform outputs many logs, discard them
		log.SetOutput(ioutil.Discard)
	}

	log := common.NewLogger(Name, conf.Debug)

	// init terraformer
	tr, err := New(conf, log)
	if err != nil {
		t.Errorf("err while creating terraformer %s", err.Error())
	}
	defer tr.Close()

	// init terraformer's kite
	k, err := tr.Kite()
	if err != nil {
		t.Errorf(err.Error())
	}
	defer k.Close()

	k.Config.DisableAuthentication = true

	go k.Run()
	defer k.Close()
	<-k.ServerReadyNotify()

	if err := f(k); err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

func TestApplyAndDestroy(t *testing.T) {
	local := kite.New("testing", "1.0.0")

	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		req := TerraformRequest{
			Content:   SampleTF,
			Variables: variables,
			ContentID: "test_file",
		}

		response, err := tfr.Tell("apply", req)
		if err != nil {
			return err
		}

		res := terraform.State{}
		if err := response.Unmarshal(&res); err != nil {
			return err
		}

		if len(res.Modules) != 1 {
			return fmt.Errorf("expected Modules to have length 1, got: %d", len(res.Modules))
		}

		if len(res.Modules[0].Resources) != 7 {
			return fmt.Errorf("Expected Resources to have length 7, got: %d", len(res.Modules[0].Resources))
		}

		response, err = tfr.Tell("destroy", req)
		if err != nil {
			return err
		}

		res = terraform.State{}
		if err := response.Unmarshal(&res); err != nil {
			return err
		}

		if len(res.Modules) != 1 {
			return fmt.Errorf("expected Modules to have length 1, got: %d", len(res.Modules))
		}

		if len(res.Modules[0].Resources) != 0 {
			return fmt.Errorf("Expected Resources to have length 0, got: %d", len(res.Modules[0].Resources))
		}

		return nil
	})

}

func TestPlan(t *testing.T) {
	local := kite.New("testing", "1.0.0")
	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		req := TerraformRequest{
			Content:   SampleTF,
			Variables: variables,
			ContentID: "test_file",
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
