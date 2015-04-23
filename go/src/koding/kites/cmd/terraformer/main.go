package main

import (
	"io/ioutil"
	"koding/kites/common"
	"koding/kites/terraformer"
	"koding/kites/terraformer/kodingcontext"
	"log"
	"os"
	"path"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/s3"
)

func main() {
	conf := &terraformer.Config{}
	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	if !conf.Debug {
		// hashicorp.terraform outputs many logs, discard them
		log.SetOutput(ioutil.Discard)
	}

	log := common.NewLogger(terraformer.Name, conf.Debug)

	// init s3 auth
	awsAuth, err := aws.GetAuth(conf.AWS.Key, conf.AWS.Secret)
	if err != nil {
		log.Fatal(err.Error())
	}

	// we are only using us east
	awsS3Bucket := s3.New(awsAuth, aws.USEast).Bucket(conf.AWS.Bucket)

	if err := awsS3Bucket.PutBucket(s3.Private); err != nil {
		if s3err, ok := err.(*s3.Error); ok {
			log.Fatal("s3err %# v", s3err)
		} else {
			log.Fatal("err while creating bucket %s", err)
		}
	}

	//TODO(cihangir) find a better place to store the temp files
	wd, err := os.Getwd()
	if err != nil {
		log.Fatal("err while getting working dir %s", err)
	}

	localFileBasePath := path.Join(wd, conf.AWS.Bucket)

	if err := os.MkdirAll(localFileBasePath, os.ModePerm); err != nil {
		log.Fatal("err while creating local folder %s", err)
	}

	ls := kodingcontext.NewFileStorage(conf.AWS.Bucket)
	rs := kodingcontext.NewS3Storage(awsS3Bucket)

	c, err := kodingcontext.Init(ls, rs)
	if err != nil {
		log.Fatal(err.Error())
	}
	defer kodingcontext.Close()

	k, err := terraformer.NewKite(conf, c, log)
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := k.RegisterForever(k.RegisterURL(true)); err != nil {
		log.Fatal(err.Error())
	}

	k.Run()
}
