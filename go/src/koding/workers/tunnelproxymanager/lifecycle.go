package main

import (
	"errors"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/koding/logging"
)

type LifeCycle struct {
	closed          bool
	closeChan       chan chan struct{}
	mu              sync.Mutex
	sqs             *sqs.SQS
	sns             *sns.SNS
	autoscaling     *autoscaling.AutoScaling
	log             logging.Logger
	queueURL        *string
	queueARN        *string
	subscriptionARN *string
	topicARN        *string
}

func NewLifeCycle(config *aws.Config, log logging.Logger, queueName string) (*LifeCycle, error) {
	lc := &LifeCycle{
		closed:      false,
		closeChan:   make(chan chan struct{}),
		sqs:         sqs.New(config),
		sns:         sns.New(config),
		autoscaling: autoscaling.New(config),
		log:         log,
	}

	return lc, nil

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
	recieveResp, err := l.sqs.ReceiveMessage(&sqs.ReceiveMessageInput{
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
		if _, err := l.sqs.DeleteMessage(&sqs.DeleteMessageInput{
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
