package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/koding/logging"
)

// maxIteration holds max iteration count for fetching items from aws resources
const maxIteration = 100

var (
	errTopicNotFound         = errors.New("topic not found")
	errSusbscriptionNotFound = errors.New("subscription not found")
	errMaxIterationReached   = errors.New("iteration terminated")
)

// EnureSNS creates or gets required Topic ARN for lifecycle management, that
// will be attached to autoscaling group, this function is idempotent, multiple
// calls will result with same response
func (l *LifeCycle) EnureSNS(topicName string) error {
	snsLogger := l.log.New("SNS")
	snsLogger.Debug("getting SNS...")

	err := l.getSNS(snsLogger, topicName)
	if err == errTopicNotFound {
		return l.createSNS(snsLogger, topicName)
	}
	if err != nil {
		snsLogger.Debug("SNS is ready")
	}

	return err
}

func (l *LifeCycle) getSNS(snsLogger logging.Logger, topicName string) error {
	iteration := 0
	// try to find our SNS Topic
	for {
		// just be paranoid about remove api calls, dont harden too much
		if iteration == maxIteration {
			return errMaxIterationReached
		}
		log := snsLogger.New("iteration", iteration)

		iteration++

		// for next pagination, if required
		var nextToken *string

		log.Debug("fetching SNS...")
		listTopicResp, err := l.sns.ListTopics(&sns.ListTopicsInput{
			NextToken: nextToken,
		})
		if err != nil {
			return err
		}

		if listTopicResp == nil {
			return errors.New("malformed response")
		}

		for _, topic := range listTopicResp.Topics {
			resources := strings.Split(*topic.TopicARN, ":")
			name := resources[len(resources)-1]
			if name == topicName {
				l.topicARN = topic.TopicARN
				log.Debug("%s topic is found. ARN: %s", topicName, *l.topicARN)
				return nil
			}
		}

		// if we reach to end, nothing to do left
		if listTopicResp.NextToken == nil || *listTopicResp.NextToken == "" {
			return errTopicNotFound
		}

		// assign next token
		nextToken = listTopicResp.NextToken

	}
}

func (l *LifeCycle) createSNS(snsLogger logging.Logger, topicName string) error {
	_, err := l.sns.CreateTopic(&sns.CreateTopicInput{
		Name: aws.String(topicName), // Required
	})
	if err != nil {
		return err
	}

	snsLogger.Debug("created %s SNS topic", topicName)
	return nil
}

// var policy = `{
//     "Version": "2012-10-17",
//     "Id": "arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir/SQSDefaultPolicy",
//     "Statement": [
//         {
//             "Sid": "Sid1434502683447",
//             "Effect": "Allow",
//             "Principal": {
//                 "AWS": "*"
//             },
//             "Action": "SQS:SendMessage",
//             "Resource": "arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir",
//             "Condition": {
//                 "ArnEquals": {
//                     "aws:SourceArn": "arn:aws:sns:us-east-1:616271189586:tunnelproxymanager_test"
//                 }
//             }
//         }
//     ]
// }`

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

func newDefaultPolicy(topicARN, queueARN string) *policy {
	return &policy{
		Version: "2012-10-17",
		ID:      fmt.Sprintf("%s/SQSDefaultPolicy", queueARN),
		Statement: []statement{
			statement{
				Sid:    callerReferance,
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
}

// var policy = `{
//     "Version": "2012-10-17",
//     "Id": "%s/SQSDefaultPolicy",
//     "Statement": [
//         {
//             "Sid": "%s",
//             "Effect": "Allow",
//             "Principal": {
//                 "AWS": "*"
//             },
//             "Action": "SQS:SendMessage",
//             "Resource": "%s",
//             "Condition": {
//                 "ArnEquals": {
//                     "aws:SourceArn": "%s"
//                 }
//             }
//         }
//     ]
// }`

// MakeSureSQS configures a queue for listening to a predefined system
func (l *LifeCycle) MakeSureSQS(queueName string) error {
	sqsLogger := l.log.New("SQS")
	sqsLogger.Debug("working...")

	// create queue is idempotent, if it is already created returns existing one
	// all Attributes should be same tho
	createQueueResp, err := l.sqs.CreateQueue(&sqs.CreateQueueInput{
		QueueName: aws.String(queueName), // Required
		Attributes: map[string]*string{ // Required
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
			"VisibilityTimeout": aws.String("3600"), // 60 secs
		},
	})

	if err != nil {
		return err
	}

	l.queueURL = createQueueResp.QueueURL

	sqsLogger.Debug("Queue is created URL: %s", *l.queueURL)
	sqsLogger.Debug("Configuring Queue...")

	resp, err := l.sqs.GetQueueAttributes(&sqs.GetQueueAttributesInput{
		QueueURL: l.queueURL, // Required
		AttributeNames: []*string{
			aws.String("QueueArn"),
			aws.String("Policy"),
		},
	})
	if err != nil {
		return err
	}

	if resp == nil {
		return errors.New("malformed response for GetQueueAttributes")
	}

	queueARN, ok := resp.Attributes["QueueArn"]
	if !ok || queueARN == nil {
		return errors.New("QueueArn not exists in Attributes")
	}
	l.queueARN = queueARN

	p1 := newDefaultPolicy(*l.topicARN, *l.queueARN)
	b, err := json.Marshal(p1)
	if err != nil {
		return err
	}

	// //	yes, data is double encoded, check below
	// b, err = json.Marshal(p1)
	// if err != nil {
	// 	return err
	// }

	// Attributes: {
	//   QueueArn: "arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir",
	//   Policy: "{\"Version\":\"2012-10-17\",\"Id\":\"arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir/SQSDefaultPolicy\",\"Statement\":[{\"Sid\":\"tunnelproxy_dev_1\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"SQS:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:616271189586:SQS-ElasticBeanstalkNotifications-Environment-cihangir\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":\"arn:aws:sns:us-east-1:616271189586:tunnelproxymanager_test\"}}}]}"
	// }
	if string(b) != *resp.Attributes["Policy"] {
		sqsLogger.Debug("Queue Policy is not correct, fixing it...")
		_, err := l.sqs.SetQueueAttributes(&sqs.SetQueueAttributesInput{
			Attributes: map[string]*string{ // Required
				"Policy": aws.String(string(b)), // Required
			},
			QueueURL: l.queueURL,
		})
		if err != nil {
			return err
		}
		sqsLogger.Debug("Queue Policy configured properly")
	}

	sqsLogger.Debug("Queue is ready")
	return nil
}

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

func (l *LifeCycle) AttachNotificationToAutoScaling() error {
	log := l.log.New("Notification")
	log.Debug("working...")

	if l.topicARN == nil {
		return errors.New("topic arn is not set")
	}

	// PutNotificationConfiguration is idempotent, if you call it with same
	// topicARN and autoscaling name
	_, err := l.autoscaling.PutNotificationConfiguration(&autoscaling.PutNotificationConfigurationInput{
		AutoScalingGroupName: aws.String("awseb-e-ps6yvwi873-stack-AWSEBAutoScalingGroup-H7SOTEVY95MP"), // sandbox autoscalinggroup
		NotificationTypes: []*string{ // Required
			aws.String("autoscaling:EC2_INSTANCE_LAUNCH"),
			aws.String("autoscaling:EC2_INSTANCE_LAUNCH_ERROR"),
			aws.String("autoscaling:EC2_INSTANCE_TERMINATE"),
			aws.String("autoscaling:EC2_INSTANCE_TERMINATE_ERROR"),
		},
		TopicARN: l.topicARN, // Required
	})
	if err != nil {
		return err
	}

	log.Debug("notification configuration is ready")
	return nil
}
