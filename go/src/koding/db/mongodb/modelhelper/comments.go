package modelhelper

import (
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func DeleteComment(selector Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(selector)
	}

	return mongodb.Run("jComments", query)
}
