package team

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

// modelHelperAdapter wraps modelhelper package with adapter interface. Thus,
// it allows to use it as ordinal object which satisfies adapter interface.
type modelHelperAdapter struct{}

func (modelHelperAdapter) GetAccount(username string) (*models.Account, error) {
	return modelhelper.GetAccount(username)
}

func (modelHelperAdapter) RelationshipCount(selector modelhelper.Selector) (int, error) {
	return modelhelper.RelationshipCount(selector)
}

func (modelHelperAdapter) GetAllRelationships(selector modelhelper.Selector) ([]models.Relationship, error) {
	return modelhelper.GetAllRelationships(selector)
}

func (modelHelperAdapter) GetGroupsByIds(ids ...bson.ObjectId) ([]*models.Group, error) {
	return modelhelper.GetGroupsByIds(ids...)
}

func (modelHelperAdapter) GetGroup(slugName string) (*models.Group, error) {
	return modelhelper.GetGroup(slugName)
}
