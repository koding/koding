package team

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

// modelHelperAdapter wraps modelhelper package with adapter interface. Thus,
// it allows to use it as ordinal object which satisfies adapter interface.
type modelHelperAdapter struct{}

func (modelHelperAdapter) GetGroup(slugName string) (*models.Group, error) {
	return modelhelper.GetGroup(slugName)
}

func (modelHelperAdapter) IsParticipant(username, groupName string) (bool, error) {
	return modelhelper.IsParticipant(username, groupName)
}

func (modelHelperAdapter) FetchAccountGroups(username string) ([]*models.Group, error) {
	return modelhelper.FetchAccountGroups(username)
}
