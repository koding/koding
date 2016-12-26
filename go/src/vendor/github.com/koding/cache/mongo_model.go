package cache

import (
	"time"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Document holds the key-value pair for mongo cache
type Document struct {
	Key      string      `bson:"_id" json:"_id"`
	Value    interface{} `bson:"value" json:"value"`
	ExpireAt time.Time   `bson:"expireAt" json:"expireAt"`
}

// getKey fetches the key with its key
func (m *MongoCache) get(key string) (*Document, error) {
	keyValue := new(Document)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"_id": key,
			"expireAt": bson.M{
				"$gt": time.Now().UTC(),
			}}).One(&keyValue)
	}

	err := m.run(m.CollectionName, query)
	if err != nil {
		return nil, err
	}

	return keyValue, nil
}

func (m *MongoCache) set(key string, duration time.Duration, value interface{}) error {
	update := bson.M{
		"_id":      key,
		"value":    value,
		"expireAt": time.Now().Add(duration),
	}

	query := func(c *mgo.Collection) error {
		_, err := c.UpsertId(key, update)
		return err
	}

	return m.run(m.CollectionName, query)
}

// deleteKey removes the key-value from mongoDB
func (m *MongoCache) delete(key string) error {
	query := func(c *mgo.Collection) error {
		err := c.RemoveId(key)
		return err
	}

	return m.run(m.CollectionName, query)
}

func (m *MongoCache) deleteExpiredKeys() error {
	var selector = bson.M{"expireAt": bson.M{
		"$lte": time.Now().UTC(),
	}}

	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return m.run(m.CollectionName, query)
}

func (m *MongoCache) run(collection string, s func(*mgo.Collection) error) error {
	session := m.mongeSession.Copy()
	defer session.Close()

	c := session.DB("").C(collection)
	return s(c)
}
