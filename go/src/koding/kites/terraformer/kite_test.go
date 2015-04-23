package terraformer

import (
	"io/ioutil"
	"log"
	"os"
	"path"
	"runtime/debug"
	"testing"

	"koding/kites/common"
	"koding/kites/terraformer/kodingcontext"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/multiconfig"
	"github.com/kr/pretty"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
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

	if !conf.Debug {
		// hashicorp.terraform outputs many logs, discard them
		log.SetOutput(ioutil.Discard)
	}

	log := common.NewLogger(Name, conf.Debug)

	// init s3 auth
	awsAuth, err := aws.GetAuth(conf.AWS.Key, conf.AWS.Secret)
	if err != nil {
		log.Fatal(err.Error())
	}

	// we are only using us east
	awsS3Bucket := s3.New(awsAuth, aws.USEast).Bucket(conf.AWS.Bucket)

	if err := awsS3Bucket.PutBucket(s3.Private); err != nil {
		if s3err, ok := err.(*s3.Error); ok {
			t.Errorf("s3err %# v", pretty.Formatter(s3err))
		} else {
			t.Errorf("err while creating bucket %s", err)
		}
	}

	wd, err := os.Getwd()
	if err != nil {
		t.Errorf("err while getting working dir %s", err)
	}

	localFileBasePath := path.Join(wd, conf.AWS.Bucket)

	if err := os.MkdirAll(localFileBasePath, os.ModePerm); err != nil {
		t.Errorf("err while creating local folder %s", err)
	}

	ls := kodingcontext.NewFileStorage(localFileBasePath)
	rs := kodingcontext.NewS3Storage(awsS3Bucket)

	c, err := kodingcontext.Init(ls, rs)
	if err != nil {
		log.Fatal(err.Error())
	}
	defer kodingcontext.Close()

	k, err := NewKite(conf, c, log)
	if err != nil {
		t.Errorf("err while creating kite %s", err.Error())
	}
	k.Config.DisableAuthentication = true

	go k.Run()
	defer k.Close()
	<-k.ServerReadyNotify()

	if err := f(k); err != nil {
		debug.PrintStack()
		t.Errorf("failed with %s", err.Error())
	}
}

func TestApplyAndDestroy(t *testing.T) {
	// t.Skip("apply should not run")
	local := kite.New("testing", "1.0.0")

	withKite(t, func(k *kite.Kite) error {
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		req := TerraformRequest{
			Content:   SampleTF,
			Variables: variables,
			Location:  "test_file",
		}

		response, err := tfr.Tell("apply", req)
		if err != nil {
			return err
		}

		res := terraform.Plan{}
		if err := response.Unmarshal(&res); err != nil {
			return err
		}

		response, err = tfr.Tell("destroy", req)
		if err != nil {
			return err
		}

		res = terraform.Plan{}
		if err := response.Unmarshal(&res); err != nil {
			return err
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
			Location:  "test_file",
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
