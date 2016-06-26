package terraformer

import (
	"fmt"
	"io/ioutil"
	"log"
	"sync"
	"testing"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

var variables = map[string]string{
	"aws_access_key":   "",
	"aws_secret_key":   "",
	"aws_region":       "sa-east-1",
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

	log := logging.NewCustom(Name, conf.Debug)

	// init terraformer
	tr, err := New(conf, log)
	if err != nil {
		t.Errorf("err while creating terraformer %s", err.Error())
	}

	// init terraformer's kite
	k, err := NewKite(tr, conf)
	if err != nil {
		t.Errorf(err.Error())
	}
	k.Config.DisableAuthentication = true
	go k.Run()
	<-k.ServerReadyNotify()

	err = f(k)
	tr.Close()
	tr.Wait()
	k.Close()
	if err != nil {
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
			Content:   SampleTFJSON,
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
			return fmt.Errorf("expected Resources to have length 7, got: %d", len(res.Modules[0].Resources))
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
			return fmt.Errorf("expected Resources to have length 0, got: %d", len(res.Modules[0].Resources))
		}

		return nil
	})

}

func TestPlanWithMultiReq(t *testing.T) {
	local := kite.New("testing", "1.0.0")
	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		callCount := 10
		var wg sync.WaitGroup
		wg.Add(callCount)

		fail := 0
		success := 0
		var mu sync.Mutex

		for i := 0; i < callCount; i++ {
			go func(seq int) {
				req := TerraformRequest{
					Content:   SampleTFJSON,
					Variables: variables,
					ContentID: fmt.Sprintf("test_file_%d", seq),
				}

				_, err := tfr.Tell("plan", req)
				mu.Lock()
				if err != nil {
					fail++
				} else {
					success++
				}
				mu.Unlock()
				wg.Done()

			}(i)
		}

		wg.Wait()

		if fail > 0 {
			return fmt.Errorf("fail should be 0, got %d", fail)
		}

		if success != callCount {
			return fmt.Errorf("success should be %d, got %d", callCount, success)
		}

		return nil
	})
}

func TestPlanWithLockedResource(t *testing.T) {
	local := kite.New("testing", "1.0.0")
	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		callCount := 10
		var wg sync.WaitGroup
		wg.Add(callCount)

		fail := 0
		success := 0
		var mu sync.Mutex

		for i := 0; i < callCount; i++ {
			go func(seq int) {
				req := TerraformRequest{
					Content:   SampleTFJSON,
					Variables: variables,
					ContentID: "test_file_locked",
				}

				_, err := tfr.Tell("plan", req)
				mu.Lock()
				if err != nil {
					fail++
				} else {
					success++
				}
				mu.Unlock()
				wg.Done()

			}(i)
		}

		wg.Wait()

		if fail < callCount-1 {
			return fmt.Errorf("fail should be lt %d, got %d", callCount-1, fail)
		}

		if success != 1 {
			return fmt.Errorf("success should be 1, got %d", success)
		}

		return nil
	})
}
