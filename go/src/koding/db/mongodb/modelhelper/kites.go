package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewKite() *models.Kite {
	return &models.Kite{
		KiteBase: models.KiteBase{
			Id: bson.NewObjectId(),
		},
	}
}

func UpsertKite(kite *models.Kite) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"uuid": kite.Uuid}, kite)
		return err
	}

	return mongodb.Run("jKites", query)
}

func GetKite(uuid string) (*models.Kite, error) {
	kite := models.Kite{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uuid": uuid}).One(&kite)
	}

	err := mongodb.Run("jKites", query)
	if err != nil {
		return nil, err
	}
	return &kite, nil
}

func UpdateKite(kite *models.Kite) error {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"uuid": kite.Uuid}, kite)
	}

	return mongodb.Run("jKites", query)
}

func DeleteKite(uuid string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"uuid": uuid})
	}

	return mongodb.Run("jKites", query)
}

func SizeKites() (int, error) {
	var count int
	var err error
	query := func(c *mgo.Collection) error {
		count, err = c.Count()
		return err
	}

	err = mongodb.Run("jKites", query)
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

	mongodb.Run("jKites", query)
	return kites
}
