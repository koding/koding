package main

import (
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

func main() {
	conf := &Config{}

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)
	config := &aws.Config{
		Credentials: credentials.NewStaticCredentials(
			conf.AccessKeyID,
			conf.SecretAccessKey,
			"",
		),
		Region:     "us-east-1",
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

	recordManager, err := New(config, log)
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := recordManager.Init(); err != nil {
		log.Fatal(err.Error())
	}

	queueName := "SQS-ElasticBeanstalkNotifications-Environment-" + ebEnvName

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
				Message: aws.String("bu benim mesajin bodysi"), // Required
				// MessageAttributes: map[string]*sns.MessageAttributeValue{
				// 	"Key": { // Required
				// 		DataType:    aws.String("String"), // Required
				// 		BinaryValue: []byte("PAYLOAD"),
				// 		StringValue: aws.String("String"),
				// 	},
				// 	// More values...
				// },
				// MessageStructure: aws.String("messageStructure"),
				// Subject:          aws.String("subject"),
				// TargetARN:        aws.String("String"),
				TopicARN: l.topicARN,
			}
			resp, err := l.sns.Publish(params)
			fmt.Println("resp-->", *resp.MessageID)
			// _, err := l.sqs.SendMessage(&sqs.SendMessageInput{
			// 	MessageBody:  aws.String("bu benim mesajin bodysi"), // Required
			// 	QueueURL:     l.queueURL,                            // Required
			// 	DelaySeconds: aws.Long(0),
			// 	MessageAttributes: map[string]*sqs.MessageAttributeValue{
			// 		"Key": &sqs.MessageAttributeValue{ // Required
			// 			DataType:    aws.String("String"), // Required
			// 			StringValue: aws.String("String value"),
			// 		},
			// 	},
			// })
			if err != nil {
				if awsErr, ok := err.(awserr.Error); ok {
					// Generic AWS Error with Code, Message, and original error (if any)
					fmt.Println(awsErr.Code(), awsErr.Message(), awsErr.OrigErr())
					if reqErr, ok := err.(awserr.RequestFailure); ok {
						// A service error occurred
						fmt.Println(reqErr.Code(), reqErr.Message(), reqErr.StatusCode(), reqErr.RequestID())
					}
				} else {
					// This case should never be hit, the SDK should always return an
					// error which satisfies the awserr.Error interface.
					fmt.Println(err.Error())
				}
			}

			time.Sleep(time.Second * 3)
		}
	}()

	err = l.Listen(func(body *string) error {
		// fmt.Println("body-->", *body)
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
