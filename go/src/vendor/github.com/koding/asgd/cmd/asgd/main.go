package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/asgd"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

type Conf struct {
	Name string

	// required
	AccessKeyID     string
	SecretAccessKey string

	// can be overriden
	Region          string
	AutoScalingName string

	Execute string

	// optional
	Debug bool
}

func main() {
	c := &Conf{}
	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "ASGD"},
		&multiconfig.FlagLoader{},
	)
	mc.MustLoad(c)

	conf := &asgd.Config{
		Name:            c.Name,
		AccessKeyID:     c.AccessKeyID,
		SecretAccessKey: c.SecretAccessKey,
		Region:          c.Region,
		AutoScalingName: c.AutoScalingName,
		Debug:           c.Debug,
	}

	session, err := asgd.Configure(conf)
	if err != nil {
		log.Fatal("Reading config failed: ", err.Error())
	}

	log := logging.NewCustom("asgd", conf.Debug)
	// remove formatting from call stack and output correct line
	log.SetCallDepth(1)

	// create lifecycle
	l := asgd.NewLifeCycle(session, log, conf.AutoScalingName)

	// configure lifecycle with system name
	if err := l.Configure(conf.Name); err != nil {
		log.Fatal(err.Error())
	}

	done := registerSignalHandler(l, log)
	// listen to lifecycle events
	if err := l.Listen(process(c.Execute)); err != nil {
		log.Fatal(err.Error())
	}

	<-done
}

func process(execute string) func(instances []*ec2.Instance) error {
	return func(instances []*ec2.Instance) error {
		tmpfile, err := ioutil.TempFile("", "content")
		if err != nil {
			log.Fatal(err)
		}

		defer os.Remove(tmpfile.Name()) // clean up
		if err := json.NewEncoder(tmpfile).Encode(instances); err != nil {
			return err
		}

		if err := tmpfile.Close(); err != nil {
			return err
		}

		cmd := exec.Command(execute, "-file", tmpfile.Name())
		if err := cmd.Run(); err != nil {
			return err
		}

		return nil
	}
}

func registerSignalHandler(l *asgd.LifeCycle, log logging.Logger) chan struct{} {
	done := make(chan struct{}, 1)

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)

		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
			log.Info("recieved exit signal, closing...")
			err := l.Close()
			if err != nil {
				log.Critical(err.Error())
			}
			close(done)
		}

	}()
	return done
}
