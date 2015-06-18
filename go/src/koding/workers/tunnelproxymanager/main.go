package main

import (
	"fmt"
	"koding/workers/tunnelproxymanager/ec2info"
	"net"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

func main() {
	conf := &Config{}

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)
	region := "us-east-1"

	config := &aws.Config{
		Credentials: credentials.NewStaticCredentials(
			conf.AccessKeyID,
			conf.SecretAccessKey,
			"",
		),
		Region:     region,
		Logger:     os.Stdout,
		MaxRetries: 5,
	}

	log := NewLogger("tunnelproxymanager", conf.Debug)

	if conf.Region == "" {
		info, err := ec2info.Get()
		if uerr, ok := err.(*url.Error); ok {
			if _, ok := uerr.Err.(*net.OpError); ok {
				log.Fatal("it seems you are trying to run tunnelproxymanager in non-ec2 machine, exiting...")
			}
		}
		if err != nil {
			log.Fatal("Couldn't get region. Err: %s", err.Error())
		}
		conf.Region = info.Region
	}

	ebEnvName := os.Getenv("EB_ENV_NAME")
	if ebEnvName == "" {
		ebEnvName = conf.EBEnvName
	}

	if ebEnvName == "" {
		log.Fatal("EB Env Name can not be empty")
	}

	recordManager, err := NewRecordManager(config, log, region)
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := recordManager.Init(); err != nil {
		log.Fatal(err.Error())
	}

	queueName := "tunnelproxymanager-" + ebEnvName

	l, err := NewLifeCycle(config, log, queueName)
	if err != nil {
		log.Fatal(err.Error())
	}

	var wg sync.WaitGroup

	registerSignalHandler(l, wg)

	err = l.Listen(func(body *string) error {
		fmt.Println("got body-->")
		return nil
	})
	if err != nil {
		panic(err)
	}

	wg.Wait()
}

func NewLogger(name string, debug bool) logging.Logger {
	log := logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if debug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}

func registerSignalHandler(l *LifeCycle, wg sync.WaitGroup) {
	wg.Add(1)

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
				l.log.Info("recieved exit signal, closing...")
				err := l.Close()
				if err != nil {
					l.log.Critical(err.Error())
				}
				wg.Done()
			}
		}
	}()

	// fake data generator
	go func() {
		for {
			params := &sns.PublishInput{
				Message:  aws.String("bu benim mesajin bodysi"), // Required
				TopicARN: l.topicARN,
			}
			_, err := l.sns.Publish(params)
			if err != nil {
				fmt.Println(err.Error())
			}
			time.Sleep(time.Second * 3)
		}
	}()
}
