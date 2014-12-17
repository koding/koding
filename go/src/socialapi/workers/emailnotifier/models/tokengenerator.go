package models

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/nu7hatch/gouuid"
)

type TokenGenerator struct {
	UserContact      *UserContact
	NotificationType string
}

func NewTokenGenerator() *TokenGenerator {
	return &TokenGenerator{}
}

func (tg *TokenGenerator) CreateToken() error {
	if err := tg.validateToken(); err != nil {
		return err
	}

	return modelhelper.CreateMailToken(
		&mongomodels.NotificationMailToken{
			Recipient:        tg.UserContact.UserOldId,
			NotificationType: tg.NotificationType,
			UnsubscribeId:    tg.UserContact.Token,
			CreatedAt:        time.Now().UTC(),
		})
}

func (tg *TokenGenerator) validateToken() error {
	if tg.UserContact.UserOldId == "" {
		return fmt.Errorf("user old id is not set")
	}

	if tg.UserContact.Token == "" {
		return fmt.Errorf("token is not set")
	}

	return nil
}

func (tg *TokenGenerator) GenerateToken() (string, error) {
	uuid1, err := uuid.NewV4()
	if err != nil {
		return "", err
	}
	uuid2, err := uuid.NewV4()
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%s%s", uuid1, uuid2), nil
}
