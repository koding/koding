package mongodb

import (
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"os"
)

type MongoDB struct {
	Session *mgo.Session
	URL     string
}

var mongo *MongoDB

func init() {
	mongo = NewMongoDB(config.Current.Mongo)
}

func NewMongoDB(url string) *MongoDB {
	m := &MongoDB{
		URL: url,
	}

	m.CreateSession(m.URL)
	return m
}

func (m *MongoDB) CreateSession(url string) {
	var err error
	m.Session, err = mgo.Dial(url)
	if err != nil {
		fmt.Printf("mongodb connection error: %s/n", err)
		os.Exit(1)
		return
	}

	m.Session.SetSafe(&mgo.Safe{})
}

func (m *MongoDB) Close() {
	m.Session.Close()
}

func (m *MongoDB) Refresh() {
	m.Session.Refresh()
}

func (m *MongoDB) Copy() *mgo.Session {
	return m.Session.Copy()
}

func (m *MongoDB) GetSession() *mgo.Session {
	if m.Session == nil {
		m.CreateSession(m.URL)
	}
	return m.Copy()
}

func (m *MongoDB) Run(collection string, s func(*mgo.Collection) error) error {
	session := m.GetSession()
	defer session.Close()
	c := session.DB("").C(collection)
	return s(c)
}

func Run(collection string, s func(*mgo.Collection) error) error {
	session := mongo.GetSession()
	defer session.Close()
	c := session.DB("").C(collection)
	return s(c)
}

func One(collection, id string, result interface{}) error {
	session := mongo.GetSession()
	defer session.Close()
	return session.DB("").C(collection).FindId(bson.ObjectIdHex(id)).One(result)
}
