package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetRelationships(selector Selector) []models.Relationship {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).All(&relationships)
	}

	mongodb.Run("relationships", query)

	return relationships
}

func GetRelationship(selector Selector) (models.Relationship, error) {
	relationship := models.Relationship{}

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&relationship)
	}

	if err := mongodb.Run("relationships", query); err != nil {
		return relationship, err
	}

	return relationship, nil

}

func DeleteRelationship(selector Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return mongodb.Run("relationships", query)
}

func AddRelationship(r *models.Relationship) error {
	query := func(c *mgo.Collection) error {
		if err := c.Insert(r); err != nil {
			return err
		}
		return nil
	}

	return mongodb.Run("relationships", query)
}
