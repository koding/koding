package modelhelper

import (
	"koding/db/models"
	"time"

	"github.com/RangelReale/osin"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Authorization data
type AuthorizeData struct {
	// Authorization code
	Code string
	// Token expiration in seconds
	ExpiresIn int32
	// Requested scope
	Scope string
	// Redirect Uri from request
	RedirectUri string
	// State data from request
	State string
	// Date created
	CreatedAt time.Time
	// Data to be passed to storage. Not used by the library.
	UserData interface{}
}

// AccessData represents an access grant
type AccessData struct {
	// Previous access data, for refresh token
	AccessData *AccessData
	// Access token
	AccessToken string
	// Refresh Token. Can be blank
	RefreshToken string
	// Token expiration in seconds
	ExpiresIn int32
	// Requested scope
	Scope string
	// Redirect Uri from request
	RedirectUri string
	// Date created
	CreatedAt time.Time
	// Data to be passed to storage. Not used by the library.
	UserData interface{}
}

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

func (store *MongoStorage) Clone() osin.Storage {
	return &MongoStorage{
		session: store.session.Clone(),
	}
}

func (store *MongoStorage) Close() {
	store.session.Close()
}

func (store *MongoStorage) GetClient(id string) (osin.Client, error) {
	client := new(osin.DefaultClient)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"id": id}).One(client)
	}

	err := Mongo.Run(ClientColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) SetClient(id string, client osin.Client) error {
	query := insertQuery(client)
	return Mongo.Run(ClientColl, query)
}

func (store *MongoStorage) SaveAuthorize(data *osin.AuthorizeData) error {
	client := removeClientFromAuthorize(data)
	query := insertQuery(client)
	return Mongo.Run(AuthorizeColl, query)
}

func (store *MongoStorage) LoadAuthorize(code string) (*osin.AuthorizeData, error) {
	client := new(AuthorizeData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"code": code}).One(client)
	}

	err := Mongo.Run(AuthorizeColl, query)
	if err != nil {
		return nil, err
	}
	authData := new(osin.AuthorizeData)
	osinClient := store.createAuthorizeData(client, authData)

	return osinClient, nil
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
	acc := removeExtraFieldsFromAccess(data)
	query := insertQuery(acc)
	return Mongo.Run(AccessColl, query)
}

func (store *MongoStorage) LoadAccess(token string) (*osin.AccessData, error) {
	client := new(AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"accesstoken": token}).One(client)
	}

	err := Mongo.Run(AccessColl, query)
	if err != nil {
		return nil, err
	}

	osinData := new(osin.AccessData)
	osinClient := store.createAccessData(client, osinData)

	return osinClient, nil
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
	client := new(AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{RefreshToken: token}).One(client)
	}

	err := Mongo.Run(AccessColl, query)
	if err != nil {
		return nil, err
	}

	osinData := new(osin.AccessData)
	clientData := store.createAccessData(client, osinData)

	return clientData, nil
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
func GetAccessDataByAccessToken(token string) (*AccessData, error) {
	user := new(AccessData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"token": token}).One(user)
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
		return c.Find(bson.M{"username": userName}).One(user)
	}

	err = Mongo.Run("jUsers", query)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (store *MongoStorage) GetClientWithUserData(userData interface{}) (osin.Client, error) {
	client := new(osin.DefaultClient)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"userData": userData}).One(client)
	}

	err := Mongo.Run(ClientColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) GetAuthorizeDataWithUserData(userData interface{}) (*osin.AuthorizeData, error) {
	client := new(osin.AuthorizeData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"userData": userData}).One(client)
	}

	err := Mongo.Run(AuthorizeColl, query)
	if err != nil {
		return nil, err
	}

	return client, nil
}

func (store *MongoStorage) createAuthorizeData(copyFrom *AuthorizeData, osinData *osin.AuthorizeData) *osin.AuthorizeData {
	osinData.Code = copyFrom.Code
	osinData.ExpiresIn = copyFrom.ExpiresIn
	osinData.Scope = copyFrom.Scope
	osinData.RedirectUri = copyFrom.RedirectUri
	osinData.State = copyFrom.State
	osinData.CreatedAt = copyFrom.CreatedAt
	osinData.UserData = copyFrom.UserData

	client, err := store.GetClientWithUserData(copyFrom.UserData)
	if err != nil || client == nil {
		osinData.Client = &osin.DefaultClient{}
	} else {
		osinData.Client = client
	}

	return osinData
}

func (store *MongoStorage) createAccessData(copyFrom *AccessData, osinData *osin.AccessData) *osin.AccessData {
	if copyFrom.AccessData != nil {
		osinAccessData := store.createAccessData(copyFrom.AccessData, &osin.AccessData{})
		osinData.AccessData = osinAccessData
	}

	osinData.AccessToken = copyFrom.AccessToken
	osinData.RefreshToken = copyFrom.RefreshToken
	osinData.ExpiresIn = copyFrom.ExpiresIn
	osinData.Scope = copyFrom.Scope
	osinData.RedirectUri = copyFrom.RedirectUri
	osinData.CreatedAt = copyFrom.CreatedAt
	osinData.UserData = copyFrom.UserData

	client, err := store.GetClientWithUserData(copyFrom.UserData)
	if err != nil || client == nil {
		osinData.Client = &osin.DefaultClient{}
	} else {
		osinData.Client = client
	}

	authorizeData, err := store.GetAuthorizeDataWithUserData(copyFrom.UserData)
	if err != nil || client == nil {
		osinData.AuthorizeData = &osin.AuthorizeData{}
	} else {
		osinData.AuthorizeData = authorizeData
	}

	return osinData
}

func removeClientFromAuthorize(osinData *osin.AuthorizeData) *AuthorizeData {
	auth := &AuthorizeData{}
	auth.Code = osinData.Code
	auth.ExpiresIn = osinData.ExpiresIn
	auth.Scope = osinData.Scope
	auth.RedirectUri = osinData.RedirectUri
	auth.State = osinData.State
	auth.CreatedAt = osinData.CreatedAt
	auth.UserData = osinData.UserData

	return auth
}

func removeExtraFieldsFromAccess(osinData *osin.AccessData) *AccessData {
	acc := &AccessData{}
	acc.AccessToken = osinData.AccessToken
	acc.RefreshToken = osinData.RefreshToken
	acc.ExpiresIn = osinData.ExpiresIn
	acc.Scope = osinData.Scope
	acc.RedirectUri = osinData.RedirectUri
	acc.CreatedAt = osinData.CreatedAt
	acc.UserData = osinData.UserData
	if osinData.AccessData != nil {
		acc.AccessData = removeExtraFieldsFromAccess(osinData.AccessData)
	}

	return acc
}
