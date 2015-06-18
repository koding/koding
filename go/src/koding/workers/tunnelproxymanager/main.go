package main

import (
	"fmt"
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
	wg.Add(1)

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
				log.Info("recieved exit signal, closing...")
				err := l.Close()
				if err != nil {
					log.Critical(err.Error())
				}
				wg.Done()
			}
		}
	}()

	go func() {
		for {

			params := &sns.PublishInput{
				Message:  aws.String("bu benim mesajin bodysi"), // Required
				TopicARN: l.topicARN,
			}
			resp, err := l.sns.Publish(params)
			fmt.Println("resp-->", *resp.MessageID)
			if err != nil {
				fmt.Println(err.Error())
			}

			time.Sleep(time.Second * 3)
		}
	}()

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
