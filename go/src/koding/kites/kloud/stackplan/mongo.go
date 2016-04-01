package stackplan

import (
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stackstate"

	"github.com/hashicorp/go-multierror"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var defaultDatabase Database = &mongoDatabase{
	mongo: modelhelper.Mongo,
}

// mongoDatabase provides an implementation for the Database interface.
//
// It assumes modelhelper.Init was called before calling any of its methods.
type mongoDatabase struct {
	mongo *mongodb.MongoDB
}

var _ Database = (*mongoDatabase)(nil)

// Detach implements the Database interface.
func (db *mongoDatabase) Detach(opts *DetachOptions) error {
	const detachReason = "Stack destroy requested."

	if err := opts.Valid(); err != nil {
		return err
	}

	// 1) Detach stack from user. Failure is critical, as upon return
	//    a user would not be able to create new stack.

	detachStack := modelhelper.Selector{
		"targetName": "JStackTemplate",
		"targetId":   opts.Stack.BaseStackId,
		"sourceName": "JAccount",
		"sourceId":   opts.Stack.OriginId,
		"as":         "user",
	}

	err := modelhelper.DeleteRelationships(detachStack)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// 2) Set stack to "destroying" state.
	id := opts.Stack.Id.Hex()

	err = modelhelper.SetStackState(id, detachReason, stackstate.Destroying)
	if err != nil && err != mgo.ErrNotFound {
		// Stack state update failure is not critical, as jComputeStack
		// is going to be removed either way at the end of destroy op.
		opts.Log.Error("unable to set stack state to %q", stackstate.Destroying)
	}

	// 3) Update counters.

	err = modelhelper.DecrementOrCreateCounter(opts.Stack.Group, modelhelper.CounterStacks, 1)
	if err != nil {
		// Counter update is not crucial, nevertheless we log an error
		// if updating failed for whatever reason.
		opts.Log.Error("failure updating %q counter", modelhelper.CounterStacks)
	}

	err = modelhelper.DecrementOrCreateCounter(opts.Stack.Group, modelhelper.CounterInstances, len(opts.Stack.Machines))
	if err != nil {
		// Counter update is not crucial, nevertheless we log an error
		// if updating failed for whatever reason.
		opts.Log.Error("failure updating %q counter", modelhelper.CounterInstances)
	}

	// 4) Detach machines from user.

	detachMachines := bson.M{
		"$set": bson.M{
			"status.state": "Terminated",
			"users":        []interface{}{},
		},
	}

	err = modelhelper.UpdateMachines(detachMachines, opts.Stack.Machines...)
	if err != nil && err != mgo.ErrNotFound {
		// Detaching users from machines error is not critical, as the jMachine
		// documents are going to be deleted at the end of destroy operation.
		// Nevertheless we log error in case a troubleshooting would be needed.
		opts.Log.Error("detaching users from machines failed: %s", err)
	}

	return nil
}

// Destroy implements the Database interface.
func (db *mongoDatabase) Destroy(opts *DestroyOptions) error {
	if err := opts.Valid(); err != nil {
		return err
	}

	err := new(multierror.Error)

	for _, id := range opts.Stack.Machines {
		if e := modelhelper.DeleteMachine(id); e != nil {
			err = multierror.Append(err, e)
		}
	}

	if e := modelhelper.DeleteComputeStack(opts.Stack.Id.Hex()); e != nil {
		err = multierror.Append(err, e)
	}

	return err.ErrorOrNil()
}
