package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetRelationships(selector Selector) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).All(&relationships)
	}

	err := mongodb.Run("relationships", query)

	return relationships, err
}

func GetSomeRelationships(selector Selector, limit int) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).Limit(limit).All(&relationships)
	}

	err := mongodb.Run("relationships", query)

	return relationships, err
}

func GetRelationship(selector Selector) (models.Relationship, error) {
	relationship := models.Relationship{}

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&relationship)
	}

	err := mongodb.Run("relationships", query)

	return relationship, err

}

func DeleteRelationship(selector Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return mongodb.Run("relationships", query)
}

func AddRelationship(r *models.Relationship) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(r)
	}

	return mongodb.Run("relationships", query)
}
