package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"koding/newkite/utils"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

func NewKiteToken(username string, expiresAt time.Time) *models.KiteToken {
	return &models.KiteToken{
		ObjectId:  bson.NewObjectId(),
		Token:     utils.RandomStringLength(64),
		Username:  username,
		Kites:     make([]string, 0),
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}
}

func AddKiteToken(token *models.KiteToken) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"username": token.Username}, token)
		return err
	}

	return mongodb.Run("jKiteTokens", query)
}

func GetKiteToken(username string) (*models.KiteToken, error) {
	token := new(models.KiteToken)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&token)
	}

	err := mongodb.Run("jKiteTokens", query)
	if err != nil {
		return token, err
	}

	return token, nil
}

func DeleteKiteToken(username string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	}

	return mongodb.Run("jKiteTokens", query)
}

// Deletes the uuid in the token.Kites array that belongs to the given username
func DeleteKiteTokenUuid(username, uuid string) error {
	token, err := GetKiteToken(username)
	if err != nil {
		return err
	}

	kites := make([]string, 0)
	for _, kiteUuid := range token.Kites {
		if kiteUuid == uuid {
			continue
		}

		kites = append(kites, kiteUuid)
	}

	token.Kites = kites

	return AddKiteToken(token)
}
