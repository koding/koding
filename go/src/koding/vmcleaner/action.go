package main

import (
	"fmt"
	"koding/db/models"
)

type Action func(*models.User, int) error

var (
	templates = map[int]string{
		1: "8239b8ac-032d-4f90-80de-a144519a945c",
		2: "a987a9c0-f116-4e75-bf18-bff3c1c11b37",
	}
)

func SendEmail(user *models.User, levelId int) error {
	templateId, ok := templates[levelId]
	if !ok {
		return fmt.Errorf("template not found for level: %v", levelId)
	}

	return email.SendTemplateEmail(user.Email, templateId, nil)
}

func DeleteVM(user *models.User, _ int) error {
	return nil
}
