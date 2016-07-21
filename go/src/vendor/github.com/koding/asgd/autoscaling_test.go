package asgd

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/koding/logging"
)

func createLifeCycle(t *testing.T) *LifeCycle {
	config, awsconfig, err := Configure()
	if err != nil {
		t.Fatal(err.Error())
	}

	log := logging.NewCustom("asgd-test", config.Debug)
	log.SetCallDepth(1)

	l := NewLifeCycle(
		awsconfig,
		log,
		config.AutoScalingName,
	)
	return l
}

func TestAttachNotificationToAutoScaling(t *testing.T) {
	l := createLifeCycle(t)
	err := l.AttachNotificationToAutoScaling()
	equals(t, errTopicARNNotSet, err)

	l.topicARN = aws.String("fakearn")
	err = l.AttachNotificationToAutoScaling()
	if awsErr, ok := err.(awserr.Error); ok {
		equals(t, "ValidationError", awsErr.Code())
	} else {
		equals(t, nil, err)
	}

	asg := l.autoscaling // hold referance for previous asg
	l.autoscaling = nil
	err = l.AttachNotificationToAutoScaling()
	equals(t, errAutoscalingNotSet, err)

	l.autoscaling = asg // assing it back after we are done

	l.asgName = nil
	err = l.AttachNotificationToAutoScaling()
	equals(t, errASGNameNotSet, err)

}

func TestGetAutoScalingOperatingIPs(t *testing.T) {
	l := createLifeCycle(t)

	asgName := l.asgName
	l.asgName = nil
	ips, err := l.GetAutoScalingOperatingIPs()
	equals(t, errASGNameNotSet, err)
	equals(t, len(ips), 0)
	l.asgName = asgName

	asg := l.autoscaling // hold referance for previous asg
	l.autoscaling = nil
	ips, err = l.GetAutoScalingOperatingIPs()
	equals(t, errAutoscalingNotSet, err)
	l.autoscaling = asg // assing it back after we are done
}

// equals fails the test if exp is not equal to act.
func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
