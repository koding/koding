package emailnotifier

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/nu7hatch/gouuid"
)

func createToken(uc *UserContact, mailType, token string) error {
	mt := &mongomodels.NotificationMailToken{
		Recipient:        uc.UserOldId,
		NotificationType: emailConfig[mailType],
		UnsubscribeId:    token,
		CreatedAt:        time.Now().UTC(),
	}

	return modelhelper.CreateMailToken(mt)
}

func generateToken() (string, error) {
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
