package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
)

func DeleteComment(selector Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return Mongo.Run("jComments", query)
}

func CheckCommentExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, Mongo.Run("jComments", query)
}

func GetCommentById(id string) (*models.Comment, error) {
	comment := new(models.Comment)
	return comment, Mongo.One("jComments", id, comment)
}

func AddComment(c *models.Comment) error {
	query := insertQuery(c)
	return Mongo.Run("jComments", query)
}

func UpdateComment(c *models.Comment) error {
	query := updateByIdQuery(c.Id.Hex(), c)
	return Mongo.Run("jComments", query)
}
