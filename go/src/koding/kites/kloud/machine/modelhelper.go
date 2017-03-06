package machine

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

var modelHelper modelHelperAdapter

// modelHelperAdapter wraps modelhelper package with adapter interface. Thus,
// it allows to use it as ordinal object which satisfies adapter interface.
type modelHelperAdapter struct{}

// GetParticipatedMachinesByUsername forwards function call to modelhelper package.
func (modelHelperAdapter) GetParticipatedMachinesByUsername(username string) ([]*models.Machine, error) {
	return modelhelper.GetParticipatedMachinesByUsername(username)
}

// GetStackTemplateFieldsByIds forwards function call to modelhelper package.
func (modelHelperAdapter) GetStackTemplateFieldsByIds(
	ids []bson.ObjectId, fields []string) ([]*models.StackTemplate, error) {
	return modelhelper.GetStackTemplateFieldsByIds(ids, fields)
}

// GetMachineByID forwards fuction call to the modelhelper package.
func (modelHelperAdapter) GetMachineByID(id string) (*models.Machine, error) {
	return modelhelper.GetMachine(id)
}
