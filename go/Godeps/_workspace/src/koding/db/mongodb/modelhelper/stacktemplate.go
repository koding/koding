package modelhelper

import (
	"fmt"
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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

func CreateStackTemplate(tmpl *models.StackTemplate) error {
	query := insertQuery(tmpl)
	return Mongo.Run(StackTemplateColl, query)
}
