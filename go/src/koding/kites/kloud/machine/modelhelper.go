package machine

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2/bson"
)

// modelHelperAdapter wraps modelhelper package with adapter interface. So, it
// allows to use it as ordinal object with satisfies adapter interface.
type modelHelperAdapter struct{}

// GetMachinesByUsername forwards function call to modelhelper package.
func (modelHelperAdapter) GetMachinesByUsername(username string) ([]*models.Machine, error) {
	return modelhelper.GetMachinesByUsername(username)
}

// GetStackTemplateFieldsByIds forwards function call to modelhelper package.
func (modelHelperAdapter) GetStackTemplateFieldsByIds(
	ids []bson.ObjectId, fields []string) ([]*models.StackTemplate, error) {
	return modelhelper.GetStackTemplateFieldsByIds(ids, fields)
}
