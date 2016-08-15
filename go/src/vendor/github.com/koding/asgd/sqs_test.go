package asgd

import "testing"

func TestMakeSureSQS(t *testing.T) {
	l := createLifeCycle(t)

	queueName := ""
	err := l.MakeSureSQS(queueName)
	equals(t, errSQSNameNotSet, err)

	queueName = "testqueue"
	sqs := l.sqs
	l.sqs = nil
	err = l.MakeSureSQS(queueName)
	equals(t, errSQSNotSet, err)
	l.sqs = sqs
}

func TestNewDefaultPolicy(t *testing.T) {
	p, err := newDefaultPolicy("topicARN", "queueARN")
	equals(t, nil, err)
	const exp = `{"Version":"2012-10-17","Id":"queueARN/SQSDefaultPolicy","Statement":[{"Sid":"koding-sns-sqs-tunnel-proxy-policy","Effect":"Allow","Principal":{"AWS":"*"},"Action":"SQS:SendMessage","Resource":"queueARN","Condition":{"ArnEquals":{"aws:SourceArn":"topicARN"}}}]}`
	equals(t, exp, p)
}
