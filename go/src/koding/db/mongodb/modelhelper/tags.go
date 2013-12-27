package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

func GetTagById(id string) (*models.Tag, error) {
	tag := new(models.Tag)

	return tag, mongodb.One("jTags", id, tag)
}

func UpdateTag(t *models.Tag) error {
	// We dont need to check if tag is exists or not
	// Update methdd returns err if not found
	// _, err := GetTagById(t.Id.Hex())
	// if err != nil {
	// 	if err == mgo.ErrNotFound {
	// 		return fmt.Errorf("tag %s does not exist", t.Title)
	// 	}
	// 	return err
	// }

	query := func(c *mgo.Collection) error {
		return c.UpdateId(t.Id, t)
	}

	return mongodb.Run("jTags", query)
}
