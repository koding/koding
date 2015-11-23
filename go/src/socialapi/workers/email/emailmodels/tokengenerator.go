package emailmodels

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	uuid "github.com/satori/go.uuid"
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

func (tg *TokenGenerator) Generate() (string, error) {
	uuid1 := uuid.NewV4()
	uuid2 := uuid.NewV4()

	return fmt.Sprintf("%s%s", uuid1, uuid2), nil
}
