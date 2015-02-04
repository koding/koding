package main

import (
	"fmt"
	"koding/db/models"
)

func SendEmail(user *models.User, levelId int) error {
	templateId, ok := templates[levelId]
	if !ok {
		return fmt.Errorf("template not found for level: %v", levelId)
	}

	return controller.Email.SendTemplateEmail(user.Email, templateId, nil)
}

func DeleteVM(user *models.User, _ int) error {
	return nil
}
