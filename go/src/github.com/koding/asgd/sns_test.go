package asgd

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
)

func TestEnureSNS(t *testing.T) {
	l := createLifeCycle(t)

	queueName := ""
	err := l.EnureSNS(queueName)
	equals(t, errSNSNameNotSet, err)

	queueName = "testqueue"
	sns := l.sns
	l.sns = nil
	err = l.EnureSNS(queueName)
	equals(t, errSNSNotSet, err)
	l.sns = sns
}

func TestMakeSureSubscriptions(t *testing.T) {
	l := createLifeCycle(t)

	err := l.MakeSureSubscriptions()
	equals(t, errTopicARNNotSet, err)

	l.topicARN = aws.String("fakearn")

	err = l.MakeSureSubscriptions()
	equals(t, errQueueURLNotSet, err)
}
