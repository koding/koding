package main

import (
	"fmt"
	"socialapi/models"
)

func testNotificationOperations() {
	// createNotifications()

	if _, err := listNotifications(9176117651782380352); err != nil {
		fmt.Println(err)
	}
}

func createNotifications() {
	if err := createReplyNotification(); err != nil {
		fmt.Println("err while creating reply notification", err)
	}

	if err := createLikeNotification(); err != nil {
		fmt.Println("err while creating like notifications", err)
	}
}

func listNotifications(id int64) (*models.Notification, error) {

	url := fmt.Sprintf("/notification/%d", id)
	n := models.NewNotification()
	nI, err := sendModel("GET", url, n)
	if err != nil {
		return nil, err
	}
	return nI.(*models.Notification), nil
}

func createReplyNotification() error {
	n := models.NewReplyNotification()
	n.TargetId = 26
	return models.CreateNotification(n)
}

func createLikeNotification() error {
	n := models.NewInteractionNotification(models.NotificationContent_TYPE_LIKE)
	n.TargetId = 27
	return models.CreateNotification(n)
}
