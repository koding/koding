package cloudwatch_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/cloudwatch"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
	"testing"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

type S struct {
	cw *cloudwatch.CloudWatch
}

var _ = gocheck.Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *gocheck.C) {
	testServer.Start()
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.cw, _ = cloudwatch.NewCloudWatch(auth, aws.ServiceInfo{testServer.URL, aws.V2Signature})
}

func (s *S) TearDownTest(c *gocheck.C) {
	testServer.Flush()
}

func getTestAlarm() *cloudwatch.MetricAlarm {
	alarm := new(cloudwatch.MetricAlarm)

	alarm.AlarmName = "TestAlarm"
	alarm.MetricName = "TestMetric"
	alarm.Namespace = "TestNamespace"
	alarm.ComparisonOperator = "LessThanThreshold"
	alarm.Threshold = 1
	alarm.EvaluationPeriods = 5
	alarm.Period = 60
	alarm.Statistic = "Sum"

	return alarm
}

func (s *S) TestPutAlarm(c *gocheck.C) {
	testServer.Response(200, nil, "<RequestId>123</RequestId>")

	alarm := getTestAlarm()

	_, err := s.cw.PutMetricAlarm(alarm)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "POST")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"PutMetricAlarm"})
	c.Assert(req.Form["AlarmName"], gocheck.DeepEquals, []string{"TestAlarm"})
	c.Assert(req.Form["ComparisonOperator"], gocheck.DeepEquals, []string{"LessThanThreshold"})
	c.Assert(req.Form["EvaluationPeriods"], gocheck.DeepEquals, []string{"5"})
	c.Assert(req.Form["Threshold"], gocheck.DeepEquals, []string{"1.0000000000E+00"})
	c.Assert(req.Form["Period"], gocheck.DeepEquals, []string{"60"})
	c.Assert(req.Form["Statistic"], gocheck.DeepEquals, []string{"Sum"})
}

func (s *S) TestPutAlarmWithAction(c *gocheck.C) {
	testServer.Response(200, nil, "<RequestId>123</RequestId>")

	alarm := getTestAlarm()

	var actions []cloudwatch.AlarmAction
	action := new(cloudwatch.AlarmAction)
	action.ARN = "123"
	actions = append(actions, *action)

	alarm.AlarmActions = actions

	_, err := s.cw.PutMetricAlarm(alarm)
	c.Assert(err, gocheck.IsNil)

	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "POST")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"PutMetricAlarm"})
	c.Assert(req.Form["AlarmActions.member.1"], gocheck.DeepEquals, []string{"123"})
	c.Assert(req.Form["AlarmName"], gocheck.DeepEquals, []string{"TestAlarm"})
	c.Assert(req.Form["ComparisonOperator"], gocheck.DeepEquals, []string{"LessThanThreshold"})
	c.Assert(req.Form["EvaluationPeriods"], gocheck.DeepEquals, []string{"5"})
	c.Assert(req.Form["Threshold"], gocheck.DeepEquals, []string{"1.0000000000E+00"})
	c.Assert(req.Form["Period"], gocheck.DeepEquals, []string{"60"})
	c.Assert(req.Form["Statistic"], gocheck.DeepEquals, []string{"Sum"})
}

func (s *S) TestPutAlarmInvalidComapirsonOperator(c *gocheck.C) {
	testServer.Response(200, nil, "<RequestId>123</RequestId>")

	alarm := getTestAlarm()

	alarm.ComparisonOperator = "LessThan"

	_, err := s.cw.PutMetricAlarm(alarm)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err.Error(), gocheck.Equals, "ComparisonOperator is not valid")
}

func (s *S) TestPutAlarmInvalidStatistic(c *gocheck.C) {
	testServer.Response(200, nil, "<RequestId>123</RequestId>")

	alarm := getTestAlarm()

	alarm.Statistic = "Count"

	_, err := s.cw.PutMetricAlarm(alarm)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err.Error(), gocheck.Equals, "Invalid statistic value supplied")
}
