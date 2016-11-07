package machine

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

// modelHelperAdapter wraps modelhelper package with adapter interface. Thus,
// it allows to use it as ordinal object which satisfies adapter interface.
type modelHelperAdapter struct{}

// GetAllMachinesByUsername forwards function call to modelhelper package.
func (modelHelperAdapter) GetAllMachinesByUsername(username string) ([]*models.Machine, error) {
	return modelhelper.GetAllMachinesByUsername(username)
}

// GetStackTemplateFieldsByIds forwards function call to modelhelper package.
func (modelHelperAdapter) GetStackTemplateFieldsByIds(
	ids []bson.ObjectId, fields []string) ([]*models.StackTemplate, error) {
	return modelhelper.GetStackTemplateFieldsByIds(ids, fields)
}
