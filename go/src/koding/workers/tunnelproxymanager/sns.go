package main

import (
	"errors"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/koding/logging"
)

var (
	errTopicNotFound = errors.New("topic not found")
)

// EnureSNS creates or gets required Topic ARN for lifecycle management, that
// will be attached to autoscaling group, this function is idempotent, multiple
// calls will result with same response
func (l *LifeCycle) EnureSNS(name string) error {

	topicName := "SNS-" + name

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

	for {

		if iteration == maxIterationCount {
			return errors.New("iteration terminated")
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

		if listTopicResp.NextToken == nil || *listTopicResp.NextToken == "" {
			return errTopicNotFound
		}

		nextToken = listTopicResp.NextToken

	}
}

func (l *LifeCycle) createSNS(snsLogger logging.Logger, topicName string) error {
	topic, err := l.sns.CreateTopic(&sns.CreateTopicInput{
		Name: aws.String(topicName),
	})
	if err != nil {
		return err
	}

	l.topicARN = topic.TopicARN
	snsLogger.Debug("created %s SNS topic", topicName)
	return nil
}
