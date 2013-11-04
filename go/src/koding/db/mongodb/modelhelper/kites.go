package modelhelper

import (
	"errors"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"time"
)

const KitesCollection = "jKites"

func NewKite() *models.Kite {
	return &models.Kite{
		UpdatedAt: time.Now().UTC(),
	}
}

func UpsertKite(kite *models.Kite) error {
	if kite.ID == "" {
		panic(errors.New("Kite must have an ID field"))
	}

	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"_id": kite.ID}, kite)
		return err
	}

	return mongodb.Run(KitesCollection, query)
}

func GetKite(id string) (*models.Kite, error) {
	kite := models.Kite{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": id}).One(&kite)
	}

	err := mongodb.Run(KitesCollection, query)
	if err != nil {
		return nil, err
	}
	return &kite, nil
}

func UpdateKite(kite *models.Kite) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": kite.ID}, kite)
	}

	return mongodb.Run(KitesCollection, query)
}

func DeleteKite(id string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": id})
	}

	return mongodb.Run(KitesCollection, query)
}

func SizeKites() (int, error) {
	var count int
	var err error
	query := func(c *mgo.Collection) error {
		count, err = c.Count()
		return err
	}

	err = mongodb.Run(KitesCollection, query)
	return count, err
}

func ListKites() []*models.Kite {
	kites := make([]*models.Kite, 0)
	query := func(c *mgo.Collection) error {
		// todo use Limit() to decrease the memory overhead, future
		// improvements...
		iter := c.Find(nil).Iter()
		return iter.All(&kites)
	}

	mongodb.Run(KitesCollection, query)
	return kites
}
