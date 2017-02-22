package main

import (
	"fmt"
	"koding/workers/tunnelproxymanager"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	awssession "github.com/aws/aws-sdk-go/aws/session"
	"github.com/koding/asgd"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

const Name = "tunnelproxymanager"

func main() {
	c, err := configure()
	if err != nil {
		log.Fatal("Reading config failed: ", err.Error())
	}

	conf := &asgd.Config{
		Name:            fmt.Sprintf("%s-%s", "tunnelproxymanager", c.EBEnvName),
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

	log := logging.NewCustom(Name, conf.Debug)
	// remove formatting from call stack and output correct line
	log.SetCallDepth(1)

	route53Session := awssession.New(&aws.Config{
		Credentials: credentials.NewStaticCredentials(
			c.Route53AccessKeyID,
			c.Route53SecretAccessKey,
			"",
		),
		Region:     aws.String(conf.Region),
		MaxRetries: aws.Int(5),
	})

	// create record manager
	recordManager := tunnelproxymanager.NewRecordManager(route53Session, log, conf.Region, c.HostedZone)
	if err := recordManager.Init(); err != nil {
		log.Fatal(err.Error())
	}

	// create lifecycle
	l := asgd.NewLifeCycle(session, log, conf.AutoScalingName)

	// configure lifecycle with system name
	if err := l.Configure(conf.Name); err != nil {
		log.Fatal(err.Error())
	}

	done := registerSignalHandler(l, log)

	// listen to lifecycle events
	if err := l.Listen(recordManager.ProcessFunc); err != nil {
		log.Fatal(err.Error())
	}

	<-done
}

func registerSignalHandler(l *asgd.LifeCycle, log logging.Logger) chan struct{} {
	done := make(chan struct{}, 1)

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)

		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
			log.Info("received exit signal, closing...")
			err := l.Close()
			if err != nil {
				log.Critical(err.Error())
			}
			close(done)
		}

	}()
	return done
}

func configure() (*tunnelproxymanager.Config, error) {
	c := &tunnelproxymanager.Config{}
	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_TUNNELPROXYMANAGER"},
		&multiconfig.FlagLoader{},
	)

	mc.MustLoad(c)

	// decide on eb env name
	ebEnvName, err := getEBEnvName(c)
	if err != nil {
		return nil, err
	}

	c.EBEnvName = ebEnvName
	return c, nil
}

// getEBEnvName checks if region name is given in config, if not tries to get it
// from env variable
func getEBEnvName(conf *tunnelproxymanager.Config) (string, error) {
	if conf.EBEnvName != "" {
		return conf.EBEnvName, nil
	}

	// get EB_ENV_NAME param
	ebEnvName := os.Getenv("EB_ENV_NAME")
	if ebEnvName == "" {
		return "", fmt.Errorf("EB_ENV_NAME can not be empty")
	}
	return ebEnvName, nil
}
