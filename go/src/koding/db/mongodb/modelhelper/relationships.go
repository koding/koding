package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

func GetAllRelationships(selector Selector) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).Sort("timestamp").All(&relationships)
	}

	err := Mongo.Run("relationships", query)

	return relationships, err
}

func GetSomeRelationships(selector Selector, limit int) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).Limit(limit).All(&relationships)
	}

	err := Mongo.Run("relationships", query)

	return relationships, err
}

func GetRelationship(selector Selector) (models.Relationship, error) {
	relationship := models.Relationship{}

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&relationship)
	}

	err := Mongo.Run("relationships", query)

	return relationship, err
}

func DeleteRelationship(selector Selector) error {
	return RemoveAllDocuments("relationships", selector)
}

func AddRelationship(r *models.Relationship) error {
	query := insertQuery(r)

	return Mongo.Run("relationships", query)
}

func UpdateRelationship(r *models.Relationship) error {
	query := updateByIdQuery(r.Id.Hex(), r)
	return Mongo.Run("relationships", query)
}

func UpdateRelationships(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, options)
		return err
	}
	return Mongo.Run("relationships", query)
}

func RelationshipCount(selector Selector) (int, error) {
	var count int
	var err error
	query := func(c *mgo.Collection) error {
		count, err = c.Find(selector).Count()
		return err
	}
	return count, Mongo.Run("relationships", query)
}
