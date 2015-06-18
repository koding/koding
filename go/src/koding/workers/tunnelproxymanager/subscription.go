package main

import (
	"errors"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sns"
)

func (l *LifeCycle) MakeSureSubscriptions() error {
	if l.topicARN == nil {
		return errors.New("topic arn is not set")
	}

	if l.queueURL == nil {
		return errors.New("queue endpoint is not set")
	}

	log := l.log.New("Subscription")
	log.Debug("working...")

	// Subscribe is idempotent, if it is already created before, returns the
	// previous one
	resp, err := l.sns.Subscribe(&sns.SubscribeInput{
		Protocol: aws.String("sqs"),
		TopicARN: l.topicARN,
		Endpoint: l.queueARN,
	})
	if err != nil {
		return err
	}

	if resp == nil || resp.SubscriptionARN == nil {
		return errors.New("malformed response")
	}

	l.subscriptionARN = resp.SubscriptionARN

	log.Debug("subscription is ready")
	return nil
}
