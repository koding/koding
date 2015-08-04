package runner

import (
	"errors"
	"fmt"
	"io/ioutil"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/koding/ec2dynamicdata"
)

var (
	ErrSQSNameNotSet         = errors.New("sqs name is not set")
	ErrSQSMissingCredentials = errors.New("sqs accessKeyId/secretKey pair is missing")
	ErrQueueUrlNotSet        = errors.New("queueURL is not set")
	ErrSQSServiceNotSet      = errors.New("sqs service is not set")
)

var attributes = map[string]*string{ // Required
	// The time in seconds that the delivery of all messages in the
	// queue will be delayed
	"DelaySeconds": aws.String("0"),

	//  The limit of how many bytes a message can contain
	"MaximumMessageSize": aws.String("262144"), // 256 KiB

	// The number of seconds Amazon SQS retains a message. Integer
	// representing seconds, from 60 (1 minute) to 1209600 (14 days).
	"MessageRetentionPeriod": aws.String("3600"), // 1 hour

	//The time for which a ReceiveMessage call will wait for a message
	//to arrive
	"ReceiveMessageWaitTimeSeconds": aws.String("20"),

	// The visibility timeout for the queue. An integer from 0 to 43200
	// (12 hours). Messages will be available again if they are not
	// deleted in VisibilityTimeout
	"VisibilityTimeout": aws.String("60"), // 60 secs
}

type SQS struct {
	*sqs.SQS
	Region string

	queueURL  string
	closeChan chan struct{}
}

// InitSQS initializes the SQS queue with the given name. It creates a new
// queue/connects to an existing one. When we attempt to reconnect to an existing
// queue, its attributes must match with given attributes.
func (r *Runner) InitSQS(name string) error {
	if r.Conf.SQS.AccessKeyID == "" || r.Conf.SQS.SecretAccessKey == "" {
		return ErrSQSMissingCredentials
	}

	// decide on region name
	region, err := r.region()
	if err != nil {
		return err
	}

	awsconfig := &aws.Config{
		Credentials: credentials.NewStaticCredentials(
			r.Conf.SQS.AccessKeyID,
			r.Conf.SQS.SecretAccessKey,
			"",
		),
		Region:     region,
		Logger:     ioutil.Discard, // we are not using aws logger
		MaxRetries: 5,
	}

	sqsIns := sqs.New(awsconfig)
	r.SQS = &SQS{
		SQS:       sqsIns,
		closeChan: make(chan struct{}),
	}

	return r.configureSQSQueue(name)
}

// Consume consumes the messages. When SQS is not initialized, or
// queueURL is not set it returns error
func (r *Runner) ListenSQS(f func(*string) error) error {
	s := r.SQS
	if s.SQS == nil {
		return ErrSQSServiceNotSet
	}

	if s.queueURL == "" {
		return ErrQueueUrlNotSet
	}

	for {
		select {
		case <-s.closeChan:
			return nil
		default:
			if err := s.fetchMessage(f); err != nil {
				r.Log.Error("Could not consume message: %s", err)
			}
		}
	}
}

// region fetches given region, or tries to get it from AWS when it is
// not set
func (r *Runner) region() (string, error) {
	if r.Conf.SQS.Region != "" {
		return r.Conf.SQS.Region, nil
	}

	info, err := ec2dynamicdata.Get()
	if err != nil {
		return "", fmt.Errorf("couldn't get region: %s", err)
	}

	if info.Region == "" {
		return "", fmt.Errorf("malformed ec2dynamicdata response: %#v", info)
	}

	return info.Region, nil
}

func (r *Runner) configureSQSQueue(name string) error {
	queueName := fmt.Sprintf("SQS-%s", name)

	createQueueResp, err := r.SQS.CreateQueue(
		&sqs.CreateQueueInput{
			QueueName:  aws.String(queueName), // Required
			Attributes: attributes,
		},
	)
	if err != nil {
		return err
	}

	queueUrl := createQueueResp.QueueURL
	r.SQS.queueURL = *queueUrl

	return nil
}

// Push pushes the message to SQS with given queueURL
func (s *SQS) Push(body string) error {
	if s.queueURL == "" {
		return ErrQueueUrlNotSet
	}
	input := &sqs.SendMessageInput{}
	input.QueueURL = &s.queueURL
	input.MessageBody = &body
	_, err := s.SendMessage(input)

	return err
}

// Close stops the running consumer
func (s *SQS) Close() error {
	close(s.closeChan)

	return nil
}

func (s *SQS) fetchMessage(f func(*string) error) error {
	// try to get messages from qeueue, will longpoll for 20 secs
	recieveResp, err := s.ReceiveMessage(&sqs.ReceiveMessageInput{
		QueueURL:            &s.queueURL, // Required
		MaxNumberOfMessages: aws.Long(1),
	})
	if err != nil {
		return err
	}

	if recieveResp == nil {
		return errors.New("recieveResp is nil")
	}

	// we can operate in sync mode, becase we are already fetching one message
	for _, message := range recieveResp.Messages {
		// process message
		if err := f(message.Body); err != nil {
			return err
		}

		// if we got sucess just delete the message from queue
		if _, err := s.DeleteMessage(&sqs.DeleteMessageInput{
			QueueURL:      &s.queueURL,           // Required
			ReceiptHandle: message.ReceiptHandle, // Required
		}); err != nil {
			return err
		}
	}

	return nil
}
