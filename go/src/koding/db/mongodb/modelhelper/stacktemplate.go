package modelhelper

import (
	"errors"
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

// GetStackTemplateFieldsByIds retrieves a slice of stack templates matching the
// given ids and limited to the specified fields.
func GetStackTemplateFieldsByIds(ids []bson.ObjectId, fields []string) ([]*models.StackTemplate, error) {
	var stackTmpls []*models.StackTemplate

	selects := bson.M{}
	for _, f := range fields {
		selects[f] = 1
	}

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{
			"_id": bson.M{"$in": ids},
		}).Select(selects).Iter()

		for st := new(models.StackTemplate); iter.Next(st); st = new(models.StackTemplate) {
			stackTmpls = append(stackTmpls, st)
		}

		return iter.Close()
	}

	return stackTmpls, Mongo.Run(StackTemplateColl, query)
}

// ErrNoAccess is returned:
//
//   - by HasTemplateAccess function, when user has no access
//     to the stack template
//
var ErrNoAccess = errors.New("no access for the requested resource")

// HasTemplateAccess return non-nil error if the user is not allowed to access
// the given stack template. It return nil error otherwise.
func HasTemplateAccess(tmpl *models.StackTemplate, username string) error {
	switch tmpl.AccessLevel {
	case models.AccessPublic:
		return nil // everyone has access
	case models.AccessPrivate, "": // if AccessLevel is missing, we assume it's private
		originID, err := GetAccountID(username)
		if err != nil {
			return ErrNoAccess
		}

		if originID != tmpl.OriginID {
			return ErrNoAccess
		}
	case models.AccessGroup:
		if ok, err := IsParticipant(username, tmpl.Group); err != nil || !ok {
			return ErrNoAccess
		}
	default:
		return errors.New("unrecognized access level: " + tmpl.AccessLevel)
	}

	return nil
}

func CreateStackTemplate(tmpl *models.StackTemplate) error {
	query := insertQuery(tmpl)
	return Mongo.Run(StackTemplateColl, query)
}
