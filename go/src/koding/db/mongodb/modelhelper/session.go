package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetSession(token string) (*models.Session, error) {
	session := new(models.Session)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"clientId": token}).One(&session)
	}

	err := Mongo.Run("jSessions", query)
	if err != nil {
		return nil, fmt.Errorf("sessionID '%s' is not validated", token)
	}

	return session, nil
}
