package modelhelper

import (
	"errors"
	"fmt"
	"koding/db/models"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	KiteKeyValueCollection = "jKiteKV"
	KiteKeyValueDatabase   = "kite"
	AutoExpire             = false
)

func NewKeyValue(userName, kiteName, environment, key string) *models.KiteKeyValue {
	// Mongo has 24k number of collection limit in a single database
	// http://stackoverflow.com/questions/9858393/limits-of-number-of-collections-in-databases
	// thats why we have a single collection and use single index
	return &models.KiteKeyValue{
		Key:         key,
		Value:       "",
		Username:    userName,
		KiteName:    kiteName,
		Environment: environment,
		ModifiedAt:  time.Now().UTC(),
	}
}

func UpsertKeyValue(kv *models.KiteKeyValue) error {
	if kv.Key == "" {
		return errors.New("KiteKeyValue must have Key field")
	}

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{
			"key":         kv.Key,
			"username":    kv.Username,
			"kitename":    kv.KiteName,
			"environment": kv.Environment,
		}, kv)
		return err
	}

	return Mongo.RunOnDatabase(KiteKeyValueDatabase, KiteKeyValueCollection, query)
}

func GetKeyValue(userName, kiteName, environment, key string) (*models.KiteKeyValue, error) {
	kv := NewKeyValue(userName, kiteName, environment, key)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"key":         kv.Key,
			"username":    kv.Username,
			"kitename":    kv.KiteName,
			"environment": kv.Environment,
		}).One(&kv)
	}

	err := Mongo.RunOnDatabase(KiteKeyValueDatabase, KiteKeyValueCollection, query)
	if err != nil {
		return nil, err
	}

	return kv, nil
}

func EnsureKeyValueIndexes() {
	query := func(c *mgo.Collection) error {
		index := mgo.Index{
			Key:        []string{"username", "kitename", "environment", "key"},
			Unique:     true,
			DropDups:   true,
			Background: true,
			Sparse:     true,
		}
		err := c.EnsureIndex(index)
		fmt.Println("err on EnsureIndex: ", err)
		return err
	}

	Mongo.RunOnDatabase(KiteKeyValueDatabase, KiteKeyValueCollection, query)

	if AutoExpire {
		// we create an auto-expire index, so Mongo will handle the expiration on
		// key values.
		query := func(c *mgo.Collection) error {
			index := mgo.Index{
				Key:         []string{"ModifiedAt"},
				Unique:      false,
				Background:  true,
				Sparse:      true,
				ExpireAfter: 24 * 60 * 60, // expire after a day
			}
			err := c.EnsureIndex(index)
			fmt.Println("err on EnsureIndex: ", err)
			return err
		}

		Mongo.RunOnDatabase(KiteKeyValueDatabase, KiteKeyValueCollection, query)
	}
}
