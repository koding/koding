package modelhelper

import (
	"fmt"
	"koding/db/models"
	"time"

	"github.com/nu7hatch/gouuid"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const SessionsColl = "jSessions"

func GetSession(clientId string) (*models.Session, error) {
	session := new(models.Session)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"clientId": clientId}).One(&session)
	}

	if err := Mongo.Run(SessionsColl, query); err != nil {
		return nil, fmt.Errorf("sessionID '%s' is not validated; err: %s", clientId, err)
	}

	return session, nil
}

func GetSessionFromToken(token string) (*models.Session, error) {
	session := new(models.Session)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"otaToken": token}).One(&session)
	}

	if err := Mongo.Run(SessionsColl, query); err != nil {
		return nil, fmt.Errorf("otaToken '%s' is not validated; err: %s", token, err)
	}

	return session, nil
}

func RemoveToken(clientId string) error {
	updateData := bson.M{
		"otaToken": "",
	}

	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"clientId": clientId}, bson.M{"$unset": updateData})
	}

	if err := Mongo.Run(SessionsColl, query); err != nil {
		return fmt.Errorf("failed to remove the ota token for sessionID '%s'; err: %s", clientId, err)
	}

	return nil
}

func UpdateSessionIP(token string, ip string) error {
	updateData := bson.M{
		"clientIP": ip,
	}

	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"clientId": token}, bson.M{"$set": updateData})
	}

	if err := Mongo.Run(SessionsColl, query); err != nil {
		return fmt.Errorf("failed to update ip for sessionID '%s'; err: %s", token, err)
	}

	return nil
}

func CreateSession(s *models.Session) error {
	return Mongo.Run("jSessions", insertQuery(s))
}

func CreateSessionForAccount(username, groupName string) (*models.Session, error) {
	uuid1, err := uuid.NewV4()
	if err != nil {
		return nil, err
	}

	session := &models.Session{
		Id:           bson.NewObjectId(),
		ClientId:     uuid1.String(),
		ClientIP:     "127.0.0.1",
		Username:     username,
		GroupName:    groupName,
		SessionBegan: time.Now().UTC(),
		LastAccess:   time.Now().UTC(),
	}

	if err := CreateSession(session); err != nil {
		return nil, err
	}

	return session, nil
}

func GetOneSessionForAccount(username, groupName string) (*models.Session, error) {
	session := &models.Session{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"username":  username,
			"groupName": groupName,
		}).One(&session)
	}

	if err := Mongo.Run(SessionsColl, query); err != nil {
		return nil, err
	}

	return session, nil
}

func RemoveSession(username string) error {
	selector := bson.M{"username": username}
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(SessionsColl, query)
}
