package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

func NewKiteToken(username string) *models.KiteToken {
	return &models.KiteToken{
		ID:        bson.NewObjectId(),
		Username:  username,
		Expire:    0, // means infinite
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
