package asgd

import (
	"errors"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/cenkalti/backoff"
	"github.com/koding/logging"
)

var errAlreadyClosed = errors.New("already closed")

// LifeCycle handles AWS resource managements
type LifeCycle struct {
	// lifecycle management properties
	closed    bool
	closeChan chan chan struct{}
	closeMu   sync.Mutex // for syncing close operation

	// aws services
	ec2         *ec2.EC2
	sqs         *sqs.SQS
	sns         *sns.SNS
	autoscaling *autoscaling.AutoScaling

	// application wide parameters
	asgName         *string
	queueURL        *string
	queueARN        *string
	subscriptionARN *string
	topicARN        *string

	// general usage
	log logging.Logger
}

type processFunc func(*string) error

// NewLifeCycle creates a new lifecycle management system, everything begins
// with an autoscaling resource, we are listening to any change on that
// resource, to be able to listen them we are attaching a notification
// configuration to given autoscaling resource, notification configuration works
// with a TopicARN, which is basically a SNS Topic, to be able to listen from a
// Topic ARN we need a SQS, SQS is attached to Notification Topic and configured
// to pass events as soon as they occur, it also has re- try mechanism. One
// event only be handled by one manager, there wont be any race condition on
// processing that particular message. Manager is idempotent, if any given
// resource doesnt exist in the given AWS system, it will create or re-use the
// previous ones
func NewLifeCycle(session *session.Session, log logging.Logger, asgName string) *LifeCycle {
	return &LifeCycle{
		closed:      false,
		closeChan:   make(chan chan struct{}),
		ec2:         ec2.New(session),
		sqs:         sqs.New(session),
		sns:         sns.New(session),
		autoscaling: autoscaling.New(session),
		asgName:     &asgName,
		log:         log.New("lifecycle"),
	}
}

// Configure configures lifecycle, upserts SNS, SQS, Subscriptions, Notification
func (l *LifeCycle) Configure(name string) error {
	l.log.Debug("Configuring...")

	if err := l.EnureSNS(name); err != nil {
		l.log.Error("Could not ensure SNS Err: %s", err.Error())
		return err
	}

	if err := l.MakeSureSQS(name); err != nil {
		l.log.Error("Coud not ensure SQS Err: %s", err.Error())
		return err
	}

	if err := l.MakeSureSubscriptions(); err != nil {
		l.log.Error("Could not create subscription to SNS from SQS Err: %s", err.Error())
		return err
	}

	if err := l.AttachNotificationToAutoScaling(); err != nil {
		l.log.Error("Could not attach notification to autoscaling Err: %s", err.Error())
		return err
	}

	// output parameters, they are safe to be in logs
	l.log.New("queueURL").Debug(*l.queueURL)
	l.log.New("queueARN").Debug(*l.queueARN)
	l.log.New("topicARN").Debug(*l.topicARN)
	l.log.New("subscriptionARN").Debug(*l.subscriptionARN)

	l.log.Info("Lifecycle manager is ready")
	return nil
}

// Listen listens for messages that are put into lifecycle queues
func (l *LifeCycle) Listen(callback func([]*ec2.Instance) error) error {
	f := l.newProcessFunc(callback)
	// run for the first time to fix/update existing record set.
	eventName := "init proxy manager"
	if err := f(&eventName); err != nil {
		return err
	}

	for {
		select {
		case c := <-l.closeChan:
			close(c)
			return nil
		default:
			if err := l.fetchMessage(f); err != nil {
				return err
			}
		}
	}
}

func (l *LifeCycle) newProcessFunc(callback func([]*ec2.Instance) error) func(body *string) error {
	return func(body *string) error {
		l.log.Debug("got event %s", *body)

		ticker := backoff.NewTicker(backoff.NewExponentialBackOff())

		var res []*ec2.Instance
		var err error

		for _ = range ticker.C {
			if res, err = l.GetAutoScalingOperatingMachines(); err != nil {
				l.log.Error("Getting autoscaling operating IPs failed, will retry... err: %s", err.Error())
				continue
			}

			if err = callback(res); err != nil {
				l.log.Error("Upserting records failed, will retry... err: %s", err.Error())
				continue

			}

			ticker.Stop()
			break
		}
		return err
	}
}

// process gets one mesage from notification queue, passes it to given callback
// function, if it returns an error, puts the message back to queue eventually,
// if returns nil, deletes from notification queue
func (l *LifeCycle) fetchMessage(f processFunc) error {
	if l.sqs == nil {
		return errors.New("SQS service is not set")
	}

	if l.queueURL == nil {
		return errors.New("queueURL is not set")
	}

	// try to get messages from qeueue, will longpoll for 20 secs
	recieveResp, err := l.sqs.ReceiveMessage(&sqs.ReceiveMessageInput{
		QueueUrl:            l.queueURL, // Required
		MaxNumberOfMessages: aws.Int64(1),
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
		if _, err := l.sqs.DeleteMessage(&sqs.DeleteMessageInput{
			QueueUrl:      l.queueURL,            // Required
			ReceiptHandle: message.ReceiptHandle, // Required
		}); err != nil {
			return err
		}
	}
	return nil
}

// Close closes lifecycle management system for proxy machines, it doesn't
// cleanup anything
func (l *LifeCycle) Close() error {
	l.closeMu.Lock()
	if l.closed {
		l.closeMu.Unlock()
		return errAlreadyClosed
	}

	l.closed = true
	c := make(chan struct{})
	l.closeChan <- c
	l.closeMu.Unlock()

	l.log.Info("waiting for listener to exit")
	<-c
	return nil
}
