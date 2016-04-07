package modelhelper

import (
	"koding/db/models"

	"github.com/RangelReale/osin"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// collection names for the entities
const (
	ClientColl    = "jOauthClients"
	AuthorizeColl = "jOauthAuthorizations"
	AccessColl    = "jOauthAccesses"

	RefreshToken = "refreshtoken"
)

type MongoStorage struct {
	session *mgo.Session
}

func NewOauthStore(session *mgo.Session) *MongoStorage {
	storage := &MongoStorage{session}
	index := mgo.Index{
		Key:        []string{RefreshToken},
		Unique:     false, // refreshtoken is sometimes empty
		DropDups:   false,
		Background: true,
		Sparse:     true,
	}

	err := Mongo.EnsureIndex(AccessColl, index)
	if err != nil {
		panic(err)
	}

	return storage
}

func (store *MongoStorage) GetClient(id string) (*osin.Client, error) {
	client := new(osin.Client)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"id": id}).One(&client)
	}

	err := Mongo.Run(ClientColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) SetClient(id string, client *osin.Client) error {
	query := updateQuery(Selector{"id": id}, client)
	return Mongo.Run(ClientColl, query)
}

func (store *MongoStorage) SaveAuthorize(data *osin.AuthorizeData) error {
	query := updateQuery(Selector{"code": data.Code}, data)
	return Mongo.Run(AuthorizeColl, query)
}

func (store *MongoStorage) LoadAuthorize(code string) (*osin.AuthorizeData, error) {
	client := new(osin.AuthorizeData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"code": code}).One(&client)
	}

	err := Mongo.Run(AuthorizeColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) RemoveAuthorize(code string) error {
	selector := bson.M{"code": code}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(AuthorizeColl, query)
}

func (store *MongoStorage) SaveAccess(data *osin.AccessData) error {
	query := updateQuery(Selector{"accesstoken": data.AccessToken}, data)
	return Mongo.Run(AccessColl, query)
}

func (store *MongoStorage) LoadAccess(token string) (*osin.AccessData, error) {
	client := new(osin.AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"accesstoken": token}).One(&client)
	}

	err := Mongo.Run(AccessColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) RemoveAccess(token string) error {
	selector := bson.M{"accesstoken": token}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(AccessColl, query)
}

func (store *MongoStorage) LoadRefresh(token string) (*osin.AccessData, error) {
	client := new(osin.AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{RefreshToken: token}).One(&client)
	}

	err := Mongo.Run(AccessColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) RemoveRefresh(token string) error {
	selector := bson.M{RefreshToken: token}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(AccessColl, query)
}

// GetAccessDataByAccessToken fetches the user data given access token
func GetAccessDataByAccessToken(token string) (*osin.AccessData, error) {
	user := new(osin.AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"token": token}).One(&user)
	}

	err := Mongo.Run(AccessColl, query)
	if err != nil {
		return nil, err
	}

	return user, nil
}

// GetUserByAccessToken fetches the user with given access token
func GetUserByAccessToken(token string) (*models.User, error) {
	accessData, err := GetAccessDataByAccessToken(token)
	if err != nil {
		return nil, err
	}

	user := new(models.User)

	userName := accessData.UserData.(string)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": userName}).One(&user)
	}

	err = Mongo.Run("jUsers", query)
	if err != nil {
		return nil, err
	}

	return user, nil
}
