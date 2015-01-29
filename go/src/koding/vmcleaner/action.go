package main

import "koding/db/models"

type Action func(*models.User, int) error

func SendEmail(user *models.User, levelId int) error {
	return nil
}

func DeleteVM(user *models.User, _ int) error {
	return nil
}
