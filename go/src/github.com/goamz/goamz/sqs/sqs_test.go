package sqs

import (
	"crypto/md5"
	"fmt"
	"github.com/goamz/goamz/aws"
	"github.com/motain/gocheck"
	"hash"
)

var _ = gocheck.Suite(&S{})

type S struct {
	HTTPSuite
	sqs *SQS
}

func (s *S) SetUpSuite(c *gocheck.C) {
	s.HTTPSuite.SetUpSuite(c)
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.sqs = New(auth, aws.Region{SQSEndpoint: testServer.URL})
}

func (s *S) TestCreateQueue(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestCreateQueueXmlOK)

	resp, err := s.sqs.CreateQueue("testQueue")
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	fmt.Printf("%+v\n", req)
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"CreateQueue"})
	c.Assert(req.Form["Attribute.1.Name"], gocheck.DeepEquals, []string{"VisibilityTimeout"})
	c.Assert(req.Form["Attribute.1.Value"], gocheck.DeepEquals, []string{"30"})

	c.Assert(resp.Url, gocheck.Equals, "http://sqs.us-east-1.amazonaws.com/123456789012/testQueue")
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestCreateQueueWithTimeout(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestCreateQueueXmlOK)

	s.sqs.CreateQueueWithTimeout("testQueue", 180)
	req := testServer.WaitRequest()

	// TestCreateQueue() tests the core functionality, just check the timeout in this test
	c.Assert(req.Form["Attribute.1.Name"], gocheck.DeepEquals, []string{"VisibilityTimeout"})
	c.Assert(req.Form["Attribute.1.Value"], gocheck.DeepEquals, []string{"180"})
}

func (s *S) TestCreateQueueWithAttributes(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestCreateQueueXmlOK)

	s.sqs.CreateQueueWithAttributes("testQueue", map[string]string{
		"ReceiveMessageWaitTimeSeconds": "20",
		"VisibilityTimeout":             "240",
	})
	req := testServer.WaitRequest()

	// TestCreateQueue() tests the core functionality, just check the timeout in this test
	c.Assert(req.Form["Attribute.1.Name"], gocheck.DeepEquals, []string{"ReceiveMessageWaitTimeSeconds"})
	c.Assert(req.Form["Attribute.1.Value"], gocheck.DeepEquals, []string{"20"})
	c.Assert(req.Form["Attribute.2.Name"], gocheck.DeepEquals, []string{"VisibilityTimeout"})
	c.Assert(req.Form["Attribute.2.Value"], gocheck.DeepEquals, []string{"240"})
}

func (s *S) TestListQueues(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestListQueuesXmlOK)

	resp, err := s.sqs.ListQueues("")
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(len(resp.QueueUrl), gocheck.Not(gocheck.Equals), 0)
	c.Assert(resp.QueueUrl[0], gocheck.Equals, "http://sqs.us-east-1.amazonaws.com/123456789012/testQueue")
	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "725275ae-0b9b-4762-b238-436d7c65a1ac")
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestDeleteQueue(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestDeleteQueueXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}
	resp, err := q.Delete()
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "6fde8d1e-52cd-4581-8cd9-c512f4c64223")
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestSendMessage(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestSendMessageXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}
	resp, err := q.SendMessage("This is a test message")
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	msg := "This is a test message"
	var h hash.Hash = md5.New()
	h.Write([]byte(msg))
	c.Assert(resp.MD5, gocheck.Equals, fmt.Sprintf("%x", h.Sum(nil)))
	c.Assert(resp.Id, gocheck.Equals, "5fea7756-0ea4-451a-a703-a558b933e274")
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestSendMessageBatch(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestSendMessageBatchXmlOk)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}

	msgList := []string{"test message body 1", "test message body 2"}
	resp, err := q.SendMessageBatchString(msgList)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	for idx, msg := range msgList {
		var h hash.Hash = md5.New()
		h.Write([]byte(msg))
		c.Assert(resp.SendMessageBatchResult[idx].MD5OfMessageBody, gocheck.Equals, fmt.Sprintf("%x", h.Sum(nil)))
		c.Assert(err, gocheck.IsNil)
	}
}

func (s *S) TestDeleteMessageBatch(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestDeleteMessageBatchXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}

	msgList := []Message{*(&Message{ReceiptHandle: "gfk0T0R0waama4fVFffkjPQrrvzMrOg0fTFk2LxT33EuB8wR0ZCFgKWyXGWFoqqpCIiprQUEhir%2F5LeGPpYTLzjqLQxyQYaQALeSNHb0us3uE84uujxpBhsDkZUQkjFFkNqBXn48xlMcVhTcI3YLH%2Bd%2BIqetIOHgBCZAPx6r%2B09dWaBXei6nbK5Ygih21DCDdAwFV68Jo8DXhb3ErEfoDqx7vyvC5nCpdwqv%2BJhU%2FTNGjNN8t51v5c%2FAXvQsAzyZVNapxUrHIt4NxRhKJ72uICcxruyE8eRXlxIVNgeNP8ZEDcw7zZU1Zw%3D%3D"}),
		*(&Message{ReceiptHandle: "gfk0T0R0waama4fVFffkjKzmhMCymjQvfTFk2LxT33G4ms5subrE0deLKWSscPU1oD3J9zgeS4PQQ3U30qOumIE6AdAv3w%2F%2Fa1IXW6AqaWhGsEPaLm3Vf6IiWqdM8u5imB%2BNTwj3tQRzOWdTOePjOjPcTpRxBtXix%2BEvwJOZUma9wabv%2BSw6ZHjwmNcVDx8dZXJhVp16Bksiox%2FGrUvrVTCJRTWTLc59oHLLF8sEkKzRmGNzTDGTiV%2BYjHfQj60FD3rVaXmzTsoNxRhKJ72uIHVMGVQiAGgB%2BqAbSqfKHDQtVOmJJgkHug%3D%3D"}),
	}

	resp, err := q.DeleteMessageBatch(msgList)
	c.Assert(err, gocheck.IsNil)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	for idx, _ := range msgList {
		c.Assert(resp.DeleteMessageBatchResult[idx].Id, gocheck.Equals, fmt.Sprintf("msg%d", idx+1))
	}
}

func (s *S) TestDeleteMessageUsingReceiptHandle(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestDeleteMessageUsingReceiptXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}

	msg := &Message{ReceiptHandle: "gfk0T0R0waama4fVFffkjRQrrvzMrOg0fTFk2LxT33EuB8wR0ZCFgKWyXGWFoqqpCIiprQUEhir%2F5LeGPpYTLzjqLQxyQYaQALeSNHb0us3uE84uujxpBhsDkZUQkjFFkNqBXn48xlMcVhTcI3YLH%2Bd%2BIqetIOHgBCZAPx6r%2B09dWaBXei6nbK5Ygih21DCDdAwFV68Jo8DXhb3ErEfoDqx7vyvC5nCpdwqv%2BJhU%2FTNGjNN8t51v5c%2FAXvQsAzyZVNapxUrHIt4NxRhKJ72uICcxruyE8eRXlxIVNgeNP8ZEDcw7zZU1Zw%3D%3D"}

	resp, err := q.DeleteMessageUsingReceiptHandle(msg.ReceiptHandle)
	c.Assert(err, gocheck.IsNil)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "d6d86b7a-74d1-4439-b43f-196a1e29cd85")
}

func (s *S) TestReceiveMessage(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestReceiveMessageXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}
	resp, err := q.ReceiveMessage(5)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(len(resp.Messages), gocheck.Not(gocheck.Equals), 0)
	c.Assert(resp.Messages[0].MessageId, gocheck.Equals, "5fea7756-0ea4-451a-a703-a558b933e274")
	c.Assert(resp.Messages[0].MD5OfBody, gocheck.Equals, "fafb00f5732ab283681e124bf8747ed1")
	c.Assert(resp.Messages[0].ReceiptHandle, gocheck.Equals, "MbZj6wDWli+JvwwJaBV+3dcjk2YW2vA3+STFFljTM8tJJg6HRG6PYSasuWXPJB+CwLj1FjgXUv1uSj1gUPAWV66FU/WeR4mq2OKpEGYWbnLmpRCJVAyeMjeU5ZBdtcQ+QEauMZc8ZRv37sIW2iJKq3M9MFx1YvV11A2x/KSbkJ0=")
	c.Assert(resp.Messages[0].Body, gocheck.Equals, "This is a test message")

	c.Assert(len(resp.Messages[0].Attribute), gocheck.Not(gocheck.Equals), 0)

	expectedAttributeResults := []struct {
		Name  string
		Value string
	}{
		{Name: "SenderId", Value: "195004372649"},
		{Name: "SentTimestamp", Value: "1238099229000"},
		{Name: "ApproximateReceiveCount", Value: "5"},
		{Name: "ApproximateFirstReceiveTimestamp", Value: "1250700979248"},
	}

	for i, expected := range expectedAttributeResults {
		c.Assert(resp.Messages[0].Attribute[i].Name, gocheck.Equals, expected.Name)
		c.Assert(resp.Messages[0].Attribute[i].Value, gocheck.Equals, expected.Value)
	}

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestChangeMessageVisibility(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestReceiveMessageXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}

	resp1, err := q.ReceiveMessage(1)
	req := testServer.WaitRequest()

	testServer.PrepareResponse(200, nil, TestChangeMessageVisibilityXmlOK)

	resp, err := q.ChangeMessageVisibility(&resp1.Messages[0], 50)
	req = testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "6a7a282a-d013-4a59-aba9-335b0fa48bed")
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestGetQueueAttributes(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, TestGetQueueAttributesXmlOK)

	q := &Queue{s.sqs, testServer.URL + "/123456789012/testQueue/"}

	resp, err := q.GetQueueAttributes("All")
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/123456789012/testQueue/")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "1ea71be5-b5a2-4f9d-b85a-945d8d08cd0b")

	c.Assert(len(resp.Attributes), gocheck.Equals, 9)

	expectedResults := []struct {
		Name  string
		Value string
	}{
		{Name: "ReceiveMessageWaitTimeSeconds", Value: "2"},
		{Name: "VisibilityTimeout", Value: "30"},
		{Name: "ApproximateNumberOfMessages", Value: "0"},
		{Name: "ApproximateNumberOfMessagesNotVisible", Value: "0"},
		{Name: "CreatedTimestamp", Value: "1286771522"},
		{Name: "LastModifiedTimestamp", Value: "1286771522"},
		{Name: "QueueArn", Value: "arn:aws:sqs:us-east-1:123456789012:qfoo"},
		{Name: "MaximumMessageSize", Value: "8192"},
		{Name: "MessageRetentionPeriod", Value: "345600"},
	}

	for i, expected := range expectedResults {
		c.Assert(resp.Attributes[i].Name, gocheck.Equals, expected.Name)
		c.Assert(resp.Attributes[i].Value, gocheck.Equals, expected.Value)
	}

	c.Assert(err, gocheck.IsNil)
}
