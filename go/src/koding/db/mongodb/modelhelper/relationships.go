package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetAllRelationships(selector Selector) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).Sort("timestamp").All(&relationships)
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
		_, err := c.RemoveAll(selector)
		return err
	}

	return mongodb.Run("relationships", query)
}

func AddRelationship(r *models.Relationship) error {
	query := insertQuery(r)

	return mongodb.Run("relationships", query)
}

func UpdateRelationship(r *models.Relationship) error {
	query := updateByIdQuery(r.Id.Hex(), r)
	return mongodb.Run("relationships", query)
}
