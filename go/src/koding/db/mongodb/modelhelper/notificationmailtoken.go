package modelhelper

import (
	"koding/db/models"
)

func CreateMailToken(mt *models.NotificationMailToken) error {
	query := insertQuery(mt)

	return Mongo.Run("jNotificationMailTokens", query)
}
