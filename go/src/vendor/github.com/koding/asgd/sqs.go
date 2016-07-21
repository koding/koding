package asgd

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/koding/logging"
)

var (
	errSQSNameNotSet  = errors.New("SNS Name must not be empty")
	errSQSNotSet      = errors.New("SNS is not set")
	errQueueURLNotSet = errors.New("queue url not set")
)

// attributes holds configuration parameters for SQS queue
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

// MakeSureSQS configures a queue for listening to a predefined system
func (l *LifeCycle) MakeSureSQS(name string) error {
	if name == "" {
		return errSQSNameNotSet
	}

	if l.sqs == nil {
		return errSQSNotSet
	}

	queueName := "SQS-" + name

	sqsLogger := l.log.New("SQS").New("queueName", queueName)
	sqsLogger.Debug("Preparing SQS Queue")

	if err := l.createQueue(sqsLogger, queueName); err != nil {
		return err
	}

	sqsLogger.Debug("Configuring Queue...")

	if err := l.configureQueue(sqsLogger); err != nil {
		return err
	}

	sqsLogger.Debug("SQS Queue is ready")
	return nil
}

func (l *LifeCycle) createQueue(sqsLogger logging.Logger, queueName string) error {
	if l.sqs == nil {
		return errSQSNotSet
	}

	// CreateQueue is idempotent, if it is already created returns existing one
	// all Attributes should be same with consecutive calls
	createQueueResp, err := l.sqs.CreateQueue(
		&sqs.CreateQueueInput{
			QueueName:  aws.String(queueName), // Required
			Attributes: attributes,
		},
	)
	if err != nil {
		return err
	}

	l.queueURL = createQueueResp.QueueUrl // dont forget to assign queue url

	sqsLogger.Debug("SQS Queue is created")
	return nil
}

func (l *LifeCycle) configureQueue(sqsLogger logging.Logger) error {
	// get attributes of queue
	resp, err := l.getQueueAttributes()
	if err != nil {
		return err
	}

	// create our custom policy for access management
	b, err := newDefaultPolicy(*l.topicARN, *l.queueARN)
	if err != nil {
		return err
	}

	// Attributes: {
	//   QueueArn: "arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir",
	//   Policy: "{\"Version\":\"2012-10-17\",\"Id\":\"arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir/SQSDefaultPolicy\",\"Statement\":[{\"Sid\":\"tunnelproxy_dev_1\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"SQS:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":\"arn:aws:sns:us-east-1:616271189586:tunnelproxymanager_test\"}}}]}"
	// }
	// check if current policy is valid
	if isPolicyValid(resp.Attributes, b) {
		return nil
	}

	sqsLogger.Debug("Queue Policy is not correct, fixing it...")

	_, err = l.sqs.SetQueueAttributes(&sqs.SetQueueAttributesInput{
		Attributes: map[string]*string{
			"Policy": aws.String(b),
		},
		QueueUrl: l.queueURL,
	})
	if err != nil {
		return err
	}

	sqsLogger.Debug("Queue Policy is configured properly")
	return nil
}

func (l *LifeCycle) getQueueAttributes() (*sqs.GetQueueAttributesOutput, error) {
	if l.queueURL == nil {
		return nil, errQueueURLNotSet
	}

	if l.sqs == nil {
		return nil, errSQSNotSet
	}

	resp, err := l.sqs.GetQueueAttributes(
		&sqs.GetQueueAttributesInput{
			QueueUrl: l.queueURL, // Required
			AttributeNames: []*string{
				// specify which ones you need in response
				aws.String("QueueArn"),
				aws.String("Policy"),
			},
		},
	)
	if err != nil {
		return nil, err
	}

	if resp == nil || resp.Attributes == nil {
		return nil, errors.New("malformed response for GetQueueAttributes")
	}

	queueARN, ok := resp.Attributes["QueueArn"]
	if !ok || queueARN == nil {
		return nil, errors.New("QueueArn not exists in Attributes")
	}

	l.queueARN = queueARN
	return resp, nil
}

type policy struct {
	Version   string      `json:"Version"`
	ID        string      `json:"Id"`
	Statement []statement `json:"Statement"`
}

type statement struct {
	Sid       string                 `json:"Sid"`
	Effect    string                 `json:"Effect"`
	Principal map[string]interface{} `json:"Principal"`
	Action    string                 `json:"Action"`
	Resource  string                 `json:"Resource"`
	Condition map[string]interface{} `json:"Condition"`
}

// newDefaultPolicy creates a new policy for giving access to SNS publish
// requests to our SNS queue
func newDefaultPolicy(topicARN, queueARN string) (string, error) {
	p := &policy{
		Version: "2012-10-17",
		ID:      fmt.Sprintf("%s/SQSDefaultPolicy", queueARN),
		Statement: []statement{
			statement{
				Sid:    "koding-sns-sqs-tunnel-proxy-policy",
				Effect: "Allow",
				Principal: map[string]interface{}{
					"AWS": "*",
				},
				Action:   "SQS:SendMessage",
				Resource: queueARN,
				Condition: map[string]interface{}{
					"ArnEquals": map[string]string{
						"aws:SourceArn": topicARN,
					},
				},
			},
		},
	}

	b, err := json.Marshal(p)
	if err != nil {
		return "", err
	}

	return string(b), nil
}

// isPolicyValid checks of given policies are same or not
func isPolicyValid(attr map[string]*string, b string) bool {
	if attr == nil {
		return false
	}

	_, ok := attr["Policy"]
	if !ok {
		return false
	}

	return b == *attr["Policy"]
}
