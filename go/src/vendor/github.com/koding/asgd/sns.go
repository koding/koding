package asgd

import (
	"errors"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sns"
)

var (
	errSNSNameNotSet  = errors.New("SNS Name must not be empty")
	errSNSNotSet      = errors.New("SNS is not set")
	errTopicARNNotSet = errors.New("topic arn is not set")
)

// EnureSNS creates or gets required Topic ARN for lifecycle management, that
// will be attached to autoscaling group. This function is idempotent, multiple
// calls will result with same response
func (l *LifeCycle) EnureSNS(name string) error {
	if name == "" {
		return errSNSNameNotSet
	}

	if l.sns == nil {
		return errSNSNotSet
	}

	topicName := "SNS-" + name

	snsLogger := l.log.New("SNS").New("topicName", topicName)

	snsLogger.Debug("Preparing SNS Topic")

	// CreateTopic is idempotent
	topic, err := l.sns.CreateTopic(&sns.CreateTopicInput{
		Name: aws.String(topicName),
	})
	if err != nil {
		return err
	}

	l.topicARN = topic.TopicArn // dont forget to assing topic ARN

	snsLogger.Debug("SNS Topic is ready")
	return nil
}

// MakeSureSubscriptions upserts subscription between sns and sqs
func (l *LifeCycle) MakeSureSubscriptions() error {
	if l.topicARN == nil {
		return errTopicARNNotSet
	}

	if l.queueURL == nil {
		return errQueueURLNotSet
	}

	log := l.log.New("SNS")
	log.Debug("Creating subscription between SNS %s and SQS %s", *l.topicARN, *l.queueARN)

	// Subscribe is idempotent, if it is already created before, returns the
	// previous one
	resp, err := l.sns.Subscribe(&sns.SubscribeInput{
		Protocol: aws.String("sqs"),
		TopicArn: l.topicARN,
		Endpoint: l.queueARN,
	})
	if err != nil {
		return err
	}

	if resp == nil || resp.SubscriptionArn == nil {
		return errors.New("malformed response")
	}

	l.subscriptionARN = resp.SubscriptionArn

	log.Debug("Subscription is ready between SNS and SQS")
	return nil
}
