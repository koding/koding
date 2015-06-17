package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awsutil"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/aws/aws-sdk-go/service/sqs"
)

var errTopicNotFound = errors.New("topic not found")
var errSusbscriptionNotFound = errors.New("subscription not found")
var errMaxIterationReached = errors.New("iteration terminated")

const maxIteration = 10

func (l *LifeCycle) MakeSureSNS(topicName string) error {
	err := l.getSNS(topicName)
	if err == errTopicNotFound {
		return l.createSNS(topicName)
	}

	return err
}

func (l *LifeCycle) getSNS(topicName string) error {
	iteration := 0
	for {
		iteration++

		if iteration == maxIteration {
			return errMaxIterationReached
		}

		// for pagination
		var nextToken *string

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
				l.log.Info("%s topic is found. ARN: %s", topicName, *l.topicARN)
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

	return nil
}

func (l *LifeCycle) createSNS(topicName string) error {
	_, err := l.sns.CreateTopic(&sns.CreateTopicInput{
		Name: aws.String(topicName), // Required
	})

	return err
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

func (l *LifeCycle) MakeSureSQS(queueName string) error {
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
	// Pretty-print the response data.
	fmt.Println("123123", awsutil.StringValue(resp))
	if resp == nil {
		return errors.New("malformed response for GetQueueAttributes")
	}

	queueARN, ok := resp.Attributes["QueueArn"]
	if !ok || queueARN == nil {
		return errors.New("QueueArn not exists in Attributes")
	}
	l.queueARN = queueARN

	p1 := newDefaultPolicy(*l.topicARN, *l.queueARN)
	// p2 := &policy{}
	b, err := json.Marshal(p1)
	if err != nil {
		return err
	}

	b, err = json.Marshal(p1)
	if err != nil {
		return err
	}
	if string(b) == *resp.Attributes["Policy"] {
		fmt.Println("11111-->", 11111)
	} else {
		resp, err := l.sqs.SetQueueAttributes(&sqs.SetQueueAttributesInput{
			Attributes: map[string]*string{ // Required
				"Policy": aws.String(string(b)), // Required
			},
			QueueURL: l.queueURL,
		})
		if err != nil {
			return err
		}

		// Pretty-print the response data.
		fmt.Println(123, awsutil.StringValue(resp))
	}

	return nil
}

func (l *LifeCycle) MakeSureSubscriptions() error {
	if l.topicARN == nil {
		return errors.New("topic arn is not set")
	}

	if l.queueURL == nil {
		return errors.New("queue endpoint is not set")
	}

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
	// Pretty-print the response data.
	fmt.Println(awsutil.StringValue(resp))
	return nil
}

var errAutoscalingNotificationNotFound = errors.New("autoscaling notification not found")

func (l *LifeCycle) getNotificationConfig(autoscalingGroupName string) error {
	iteration := 0
	// try to get our hosted zone
	for {
		l.log.New("iteration", iteration).Debug("fetching autoscaling notification configuration")

		// for pagination
		var nextToken *string

		autoscalingNotifRes, err := l.autoscaling.DescribeNotificationConfigurations(&autoscaling.DescribeNotificationConfigurationsInput{
			AutoScalingGroupNames: []*string{aws.String(autoscalingGroupName)},
			NextToken:             nextToken,
		})
		if err != nil {
			return err
		}

		if autoscalingNotifRes == nil {
			return errors.New("malformed response")
		}

		for _, notificationConfiguration := range autoscalingNotifRes.NotificationConfigurations {
			fmt.Println(notificationConfiguration)
		}

		// if we reach to end, nothing to do left
		if autoscalingNotifRes.NextToken == nil || *autoscalingNotifRes.NextToken == "" {
			return errAutoscalingNotificationNotFound
		}

		// assign next token
		nextToken = autoscalingNotifRes.NextToken
	}

}

func (l *LifeCycle) ConfigureNotifications() error {
	l.getNotificationConfig("f")
	return nil
}
