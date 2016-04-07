package mongodb

import (
	"errors"
	"fmt"
	"os"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type MongoDB struct {
	Session *mgo.Session
	URL     string
}

func NewMongoDB(url string) *MongoDB {
	m := &MongoDB{
		URL: url,
	}

	mgo.SetStats(true)
	m.CreateSession(m.URL)
	return m
}

func (m *MongoDB) CreateSession(url string) {
	var err error
	m.Session, err = mgo.Dial(url)
	if err != nil {
		fmt.Printf("mongodb connection error: %s\n", err)
		os.Exit(1)
		return
	}

	m.Session.SetSafe(&mgo.Safe{})
	m.Session.SetMode(mgo.Strong, true)
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

func (m *MongoDB) Clone() *mgo.Session {
	return m.Session.Clone()
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

func (m *MongoDB) GetIter(collection string, s func(*mgo.Collection) *mgo.Query) *mgo.Iter {
	session := m.GetSession()
	defer session.Close()
	c := session.DB("").C(collection)
	return s(c).Iter()
}

// RunOnDatabase runs command on given database, instead of current database
func (m *MongoDB) RunOnDatabase(database, collection string, s func(*mgo.Collection) error) error {
	session := m.GetSession()
	defer session.Close()
	c := session.DB(database).C(collection)
	return s(c)
}

func (m *MongoDB) One(collection, id string, result interface{}) error {
	session := m.GetSession()
	defer session.Close()
	return session.DB("").C(collection).FindId(bson.ObjectIdHex(id)).One(result)
}

func (m *MongoDB) Iter(cl string, q func(*mgo.Collection) *mgo.Query, i func(*mgo.Iter) error) error {
	session := m.GetSession()
	defer session.Close()
	c := session.DB("").C(cl)

	var iter = q(c).Iter()
	var err = i(iter)
	if err != nil {
		return err
	}

	err = iter.Close()
	if err != nil {
		return err
	}

	if iter.Timeout() {
		return errors.New("iter timed out")
	}

	return nil
}

func (m *MongoDB) EnsureIndex(collection string, index mgo.Index) error {
	session := m.GetSession()
	defer session.Close()
	return session.DB("").C(collection).EnsureIndex(index)
}
