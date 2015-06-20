package main

import (
	"io/ioutil"
	"koding/common"
	"koding/workers/tunnelproxymanager"
	"log"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awsutil"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/logging"
)

func main() {
	conf, err := tunnelproxymanager.Configure()
	if err != nil {
		log.Fatal(err.Error()) // exit if we get any error
	}

	log := common.CreateLogger("tunnelproxymanager", conf.Debug)
	log.SetCallDepth(1)

	awsconfig := &aws.Config{
		Credentials: credentials.NewStaticCredentials(
			conf.AccessKeyID,
			conf.SecretAccessKey,
			"",
		),
		Region:     conf.Region,
		Logger:     ioutil.Discard, // we are not using aws logger
		MaxRetries: 5,
	}

	recordManager := tunnelproxymanager.NewRecordManager(awsconfig, log, conf.Region)
	if err := recordManager.Init(); err != nil {
		log.Fatal(err.Error())
	}

	queueName := "tunnelproxymanager-" + conf.EBEnvName
	l := tunnelproxymanager.NewLifeCycle(
		awsconfig,
		log,
		conf.AutoScalingName,
	)
	if err := l.Init(queueName); err != nil {
		log.Fatal(err.Error())
	}

	var wg sync.WaitGroup

	registerSignalHandler(l, log, wg)

	err = l.Listen(func(body *string) error {
		log.Debug("got event %s", *body)
		res, err := l.GetAutoScalingOperatingIPs()
		if err != nil {
			return err
		}

		log.Debug("new servers %s", awsutil.StringValue(res))
		return recordManager.UpsertRecordSet(res)
	})
	if err != nil {
		panic(err)
	}

	wg.Wait()
}

func registerSignalHandler(l *tunnelproxymanager.LifeCycle, log logging.Logger, wg sync.WaitGroup) {
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

	// fake data generator
	// go func() {
	//  for {
	//      params := &sns.PublishInput{
	//          Message:  aws.String("bu benim mesajin bodysi"), // Required
	//          TopicARN: l.topicARN,
	//      }
	//      _, err := l.sns.Publish(params)
	//      if err != nil {
	//          fmt.Println(err.Error())
	//      }
	//      time.Sleep(time.Second * 3)
	//  }
	// }()
}
