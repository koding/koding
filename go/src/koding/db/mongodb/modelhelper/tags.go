package modelhelper

import (
  "fmt"
  "koding/db/models"
  "koding/db/mongodb"
  "labix.org/v2/mgo"
)

func GetTagById(id string) (*models.Tag, error) {
  tag := new(models.Tag)
  if err := mongodb.One("jTags", id, tag); err != nil {
    return nil, err
  }

  fmt.Println("Tag", tag.Id)
  return tag, nil
}

func UpdateTag(t *models.Tag) error {
  _, err := GetTagById(t.Id.Hex())
  if err != nil {
    if err == mgo.ErrNotFound {
      return fmt.Errorf("tag %s does not exist", t.Title)
    }
    return err
  }

  query := func(c *mgo.Collection) error {
    return c.UpdateId(t.Id, t)
  }

  return mongodb.Run("jTags", query)
}
