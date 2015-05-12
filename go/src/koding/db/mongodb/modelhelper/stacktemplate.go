package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const StackTemplateColl = "jStackTemplates"

func GetStackTemplate(id string) (*models.StackTemplate, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Not valid ObjectIdHex: '%s'", id)
	}

	stackTemplate := new(models.StackTemplate)
	query := func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&stackTemplate)
	}

	if err := Mongo.Run(StackTemplateColl, query); err != nil {
		return nil, err
	}

	return stackTemplate, nil
}
