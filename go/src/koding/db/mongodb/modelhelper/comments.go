package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func DeleteComment(selector Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return mongodb.Run("jComments", query)
}

func CheckCommentExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, mongodb.Run("jComments", query)
}

func GetCommentById(id string) (*models.Comment, error) {
	comment := new(models.Comment)
	return comment, mongodb.One("jComments", id, comment)
}

func AddComment(c *models.Comment) error {
	query := insertQuery(c)
	return mongodb.Run("jComments", query)
}
