package main

import (
	"errors"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
)

func (l *LifeCycle) AttachNotificationToAutoScaling() error {
	log := l.log.New("Notification")
	log.Debug("working...")

	if l.topicARN == nil {
		return errors.New("topic arn is not set")
	}

	_, err := l.autoscaling.PutNotificationConfiguration(&autoscaling.PutNotificationConfigurationInput{
		AutoScalingGroupName: aws.String("awseb-e-ps6yvwi873-stack-AWSEBAutoScalingGroup-H7SOTEVY95MP"),
		NotificationTypes: []*string{
			aws.String("autoscaling:EC2_INSTANCE_LAUNCH"),
			aws.String("autoscaling:EC2_INSTANCE_LAUNCH_ERROR"),
			aws.String("autoscaling:EC2_INSTANCE_TERMINATE"),
			aws.String("autoscaling:EC2_INSTANCE_TERMINATE_ERROR"),
		},
		TopicARN: l.topicARN,
	})
	if err != nil {
		return err
	}

	log.Debug("notification configuration is ready")
	return nil
}
