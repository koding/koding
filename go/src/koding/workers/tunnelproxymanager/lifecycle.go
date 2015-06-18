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

// LifeCycle handles AWS resource managements
type LifeCycle struct {
	// lifecycle management properties
	closed    bool
	closeChan chan chan struct{}
	mu        sync.Mutex

	// aws services
	sqs         *sqs.SQS
	sns         *sns.SNS
	autoscaling *autoscaling.AutoScaling

	// application wide parameters
	queueURL        *string
	queueARN        *string
	subscriptionARN *string
	topicARN        *string

	// general usage
	log logging.Logger
}

// NewLifeCycle creates a new lifecycle management system, everyting begins with
// an autoscaling resource, we are listening to any change on that resource, to
// be able to listen them we are attaching a notification configuration to given
// autoscaling resource, notification configuration works with a TopicARN, which
// is basically a SNS Topic, to be able to listen from a Topic ARN we need a
// SQS, SQS is attached to Notification Topic and configured to pass events as
// soon as they occur, it also has re- try mechanism. One event only be handled
// by one manager, there wont be any race condition on processing that
// particular message. Manager is idempotent, if any given resource doesnt exist
// in the given AWS system, it will create or re-use the previous ones
func NewLifeCycle(config *aws.Config, log logging.Logger, name string) (*LifeCycle, error) {
	l := &LifeCycle{
		closed:      false,
		closeChan:   make(chan chan struct{}),
		sqs:         sqs.New(config),
		sns:         sns.New(config),
		autoscaling: autoscaling.New(config),
		log:         log.New("lifecycle"),
	}

	if err := l.EnureSNS(name); err != nil {
		log.Error("Could not ensure SNS Err: %s", err.Error())
		return nil, err
	}

	if err := l.MakeSureSQS(name); err != nil {
		log.Error("Coud not ensure SQS Err: %s", err.Error())
		return nil, err
	}

	if err := l.MakeSureSubscriptions(); err != nil {
		log.Error("Could not create subscription to SNS from SQS Err: %s", err.Error())
		return nil, err
	}

	if err := l.AttachNotificationToAutoScaling(); err != nil {
		log.Error("Could not attach notification to autoscaling Err: %s", err.Error())
		return nil, err
	}

	// output parameters
	l.log.New("queueURL").Debug(*l.queueURL)
	l.log.New("queueARN").Debug(*l.queueARN)
	l.log.New("topicARN").Debug(*l.topicARN)
	l.log.New("subscriptionARN").Debug(*l.subscriptionARN)

	l.log.Info("Lifecycle manager is ready")
	return l, nil

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

// process gets one mesage from notification queue, passes it to given callback
// function, if it returns an error, puts the message back to queue eventually,
// if returns nil, deletes from notification queue
func (l *LifeCycle) process(f func(*string) error) error {
	if l.sqs == nil {
		return errors.New("SQS service is not set")
	}

	if l.queueURL == nil {
		return errors.New("QueueURL is not set")
	}

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

// Close closes lifecycle management system for proxy machines, it doesn't
// cleanup anything
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
