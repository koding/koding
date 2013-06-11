package mongo

import (
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
)

var (
	MONGO_CONNECTION              *mgo.Session
	DATABASE                      *mgo.Database
	MONGO_CONN_STRING             = config.Current.Mongo
	MONGO_DEFAULT_COLLECTION_NAME = "relationships"
)

func GetConnection() *mgo.Session {
	if MONGO_CONNECTION == nil {
		// connnect to mongo
		var err error
		fmt.Println(MONGO_CONN_STRING)
		MONGO_CONNECTION, err = mgo.Dial(MONGO_CONN_STRING)
		if err != nil {
			fmt.Println(err)
		}
		MONGO_CONNECTION.SetSafe(&mgo.Safe{})
		fmt.Println("connection established")
	}
	return MONGO_CONNECTION
}

func GetCollection(collectionName string) *mgo.Collection {
	if DATABASE == nil {
		session := GetConnection()
		DATABASE = session.DB("")
		fmt.Println("database selected")
	}
	// defer session.Close()
	if collectionName == "" {
		collectionName = MONGO_DEFAULT_COLLECTION_NAME
	}
	//default db, as in connection string
	c := DATABASE.C(collectionName)
	return c
}

func searchCollection(databaseName, collectionName string, search func(*mgo.Collection) error) error {
	connection := GetConnection()
	defer connection.Close()
	c := connection.DB(databaseName).C(collectionName)
	return search(c)
}

func Search(databaseName, collectionName string, q interface{}, skip int, limit int) (searchResults []interface{}, searchErr string) {
	searchErr = ""
	query := func(c *mgo.Collection) error {
		fn := c.Find(q).Skip(skip).Limit(limit).All(&searchResults)
		if limit < 0 {
			fn = c.Find(q).Skip(skip).All(&searchResults)
		}
		return fn
	}
	search := func() error {
		return searchCollection(databaseName, collectionName, query)
	}
	err := search()
	if err != nil {
		searchErr = "Database Error"
	}
	return
}
