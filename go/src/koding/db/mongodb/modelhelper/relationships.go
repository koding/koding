package modelhelper

import (
	"koding/db/models"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const RelationshipColl = "relationships"

func GetAllRelationships(selector Selector) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).All(&relationships)
	}

	err := Mongo.Run(RelationshipColl, query)

	return relationships, err
}

func GetSomeRelationships(selector Selector, limit int) ([]models.Relationship, error) {
	relationships := make([]models.Relationship, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(selector).Limit(limit).All(&relationships)
	}

	err := Mongo.Run(RelationshipColl, query)

	return relationships, err
}

func GetRelationship(selector Selector) (models.Relationship, error) {
	relationship := models.Relationship{}

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&relationship)
	}

	err := Mongo.Run(RelationshipColl, query)

	return relationship, err
}

// Deletes all relationships satisfying the selector
func DeleteRelationships(selector Selector) error {
	return RemoveAllDocuments(RelationshipColl, selector)
}

// Deletes relationships with the given id
func DeleteRelationship(id bson.ObjectId) error {
	return RemoveDocument(RelationshipColl, id)
}

func AddRelationship(r *models.Relationship) error {
	query := insertQuery(r)

	return Mongo.Run(RelationshipColl, query)
}

func UpdateRelationship(r *models.Relationship) error {
	query := updateByIdQuery(r.Id.Hex(), r)
	return Mongo.Run(RelationshipColl, query)
}

func UpdateRelationships(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, options)
		return err
	}
	return Mongo.Run(RelationshipColl, query)
}

func RelationshipCount(selector Selector) (int, error) {
	var count int
	var err error
	query := func(c *mgo.Collection) error {
		count, err = c.Find(selector).Count()
		return err
	}
	return count, Mongo.Run(RelationshipColl, query)
}
