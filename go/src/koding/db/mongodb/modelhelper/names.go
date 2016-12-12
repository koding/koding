package modelhelper

import (
	"fmt"
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const jNamesColl = "jNames"

// RemoveName removes given WS
func RemoveName(id bson.ObjectId) error {
	return RemoveDocument(jNamesColl, id)
}

func GetNameBySlug(slug string) (*models.Name, error) {
	name := &models.Name{}

	query := func(c *mgo.Collection) error {
		v := fmt.Sprintf("Activity\\/%s", slug)
		s := &Selector{"slug": v}
		return c.Find(s).One(&name)
	}

	err := Mongo.Run(jNamesColl, query)

	return name, err
}

func UpdateName(name *models.Name) error {
	query := updateQuery(Selector{"name": name.Name}, name)
	return Mongo.Run(jNamesColl, query)
}
