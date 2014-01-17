package modelhelper

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetNameBySlug(slug string) (*models.Name, error) {
	name := &models.Name{}

	query := func(c *mgo.Collection) error {
		v := fmt.Sprintf("Activity\\/%s", slug)
		s := &Selector{"slug": v}
		return c.Find(s).One(&name)
	}

	err := mongodb.Run("jNames", query)

	return name, err
}

func UpdateName(name *models.Name) error {
	query := updateQuery(Selector{"name": name.Name}, name)
	return mongodb.Run("jNames", query)
}
