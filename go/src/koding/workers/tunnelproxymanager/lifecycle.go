package main

import (
	"errors"
	"sync"

	"github.com/awslabs/aws-sdk-go/aws"
	"github.com/awslabs/aws-sdk-go/service/sqs"
	"github.com/koding/logging"
)

type LifeCycle struct {
	closed    bool
	closeChan chan chan struct{}
	mu        sync.Mutex
	svc       *sqs.SQS
	log       logging.Logger
	queueURL  *string
}

func NewLifeCycle(config *aws.Config, log logging.Logger, queueName string) (*LifeCycle, error) {
	lc := &LifeCycle{
		closed:    false,
		closeChan: make(chan chan struct{}),
		svc:       sqs.New(config),
		log:       log,
	}

	if err := lc.generateQueueURL(queueName); err != nil {
		return nil, err
	}

	return lc, nil

}

func (l *LifeCycle) generateQueueURL(queueName string) error {
	// create queue is idempotent, if it is already created returns existing one
	// all Attributes should be same tho
	createQueueResp, err := l.svc.CreateQueue(&sqs.CreateQueueInput{
		QueueName: aws.String(queueName), // Required
		Attributes: &map[string]*string{ // Required
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
		},
	})

	if err != nil {
		return err
	}

	l.queueURL = createQueueResp.QueueURL

	return nil
}

// Listen listens for messages that are put into lifecycle queues
func (l *LifeCycle) Listen(f func(*string) error) error {
	for {
		select {
		case c := <-l.closeChan:
			close(c)
			return nil
		default:
			if err := l.process(f); err != nil {
				return err
			}
		}
	}

	return nil
}

func (l *LifeCycle) process(f func(*string) error) error {
	// try to get messages from qeueue, will longpoll for 20 secs
	recieveResp, err := l.svc.ReceiveMessage(&sqs.ReceiveMessageInput{
		QueueURL:            l.queueURL, // Required
		MaxNumberOfMessages: aws.Long(1),
	})
	if err != nil {
		return err
	}

	if recieveResp == nil {
		return errors.New("recieveResp is nil")
	}

	for _, message := range recieveResp.Messages {
		// process message
		if err := f(message.Body); err != nil {
			return err
		}

		// if we got sucess just delete the message from queue
		if _, err := l.svc.DeleteMessage(&sqs.DeleteMessageInput{
			QueueURL:      l.queueURL,            // Required
			ReceiptHandle: message.ReceiptHandle, // Required
		}); err != nil {
			return err
		}
	}

	return nil
}

var errAlreadyClosed = errors.New("already closed")

func (l *LifeCycle) Close() error {
	l.mu.Lock()
	if l.closed {
		l.mu.Unlock()
		return errAlreadyClosed
	}

	l.closed = true
	c := make(chan struct{})
	l.closeChan <- c
	l.mu.Unlock()

	l.log.Info("waiting for listener to exit")
	<-c
	return nil
}
