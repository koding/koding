package provider

import (
	"errors"
	"koding/db/models"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/logging"
)

// DetachOptions groups parameters for stack detach operation.
type DetachOptions struct {
	Stack *models.ComputeStack
	Log   logging.Logger
}

// Valid implements the kloud.Validator interface.
func (opts *DetachOptions) Valid() error {
	if opts == nil {
		return errors.New("invalid nil options")
	}

	if opts.Stack == nil {
		return errors.New("invalid nil stack")
	}

	return nil
}

// DestroyOptions groups parameters for stack destroy operation.
type DestroyOptions struct {
	Stack *models.ComputeStack
	Log   logging.Logger
}

// Valid implements the kloud.Validator interface.
func (opts *DestroyOptions) Valid() error {
	if opts == nil {
		return errors.New("invalid nil options")
	}

	if opts.Stack == nil {
		return errors.New("invalid nil stack")
	}

	return nil
}

// MigrationStatus describes a migration state.
type MigrationStatus string

const (
	MigrationMigrating = MigrationStatus("Migrating")
	MigrationMigrated  = MigrationStatus("Migrated")
	MigrationAborted   = MigrationStatus("Aborted")
	MigrationError     = MigrationStatus("Error")
)

// UpdateMigrationOptions groups parameters used for marking jMachine as
// migrated or updating partial migration status.
type UpdateMigrationOptions struct {
	MachineID bson.ObjectId // jMachine.objectId
	Meta      interface{}   // jMachine.meta.migration
	Log       logging.Logger
}

// MigrateOptions groups parameters needed to create stacks for
// migrated machines.
type MigrateOptions struct {
	MachineIDs []bson.ObjectId
	Machines   []interface{}
	Provider   string
	Identifier string
	Username   string
	GroupName  string
	StackName  string
	Template   string

	Log logging.Logger
}

// Database describes an interface for stack's database operations.
//
// The stack deletion operation consist of two phases - removing metadata and
// removing actual resources. The first phase is referred to as detach and
// the second - destroy. Removing metadata is removing jRelationships,
// jMachine.users docs and setting proper states on both jMachine and
// jComputeStack. Removing resources is destroying them on terraform part and
// then removing corresponding docs from mongo.
type Database interface {
	// Detach detaches user from the stack. The operation is performed
	// prior to stack reinit - it allows the stack to be concurrently
	// deleted while enabling user to start building new stack.
	Detach(*DetachOptions) error

	// Destroy removes the stack completely.
	Destroy(*DestroyOptions) error

	// UpdateMigration updates migration metadata - jMachine.migration.
	UpdateMigration(*UpdateMigrationOptions) error

	// Migrate creates a stack from migrated machines.
	Migrate(*MigrateOptions) error
}

// DatabaseBuilder is a decorator for Builder and Database values.
//
// Both are required to be non-nil.
type DatabaseBuilder struct {
	Database
	*Builder
}

// Detach detaches the stack built by the underlying Builder.
//
// Prior to calling Detach, the Builder is required to have
// the stack successfully built with the BuildStack method.
//
// Otherwise the behavior of the method is unspecified.
func (db *DatabaseBuilder) Detach() error {
	opts := &DetachOptions{
		Stack: db.Builder.Stack.Stack,
		Log:   db.log().New(db.Builder.Stack.Stack.Id.Hex()),
	}

	return db.Database.Detach(opts)
}

// Destroy destroys the stack built by the underlying Builder.
//
// Prior to calling Destroy, the Builder is required to have
// the stack successfully built with the BuildStack method.
//
// Otherwise the behavior of the method is unspecified.
func (db *DatabaseBuilder) Destroy() error {
	opts := &DestroyOptions{
		Stack: db.Builder.Stack.Stack,
		Log:   db.log().New(db.Builder.Stack.Stack.Id.Hex()),
	}

	return db.Database.Destroy(opts)
}

// UpdateMigration is responsible for updating migration status
// for the machine with specified ID.
func (db *DatabaseBuilder) UpdateMigration(opts *UpdateMigrationOptions) error {
	optsCopy := *opts

	if optsCopy.Log == nil {
		optsCopy.Log = db.log()
	}

	return db.Database.UpdateMigration(&optsCopy)
}

// Migrate creates template and a stack for the given migrated machines.
func (db *DatabaseBuilder) Migrate(opts *MigrateOptions) error {
	optsCopy := *opts

	if optsCopy.Log == nil {
		optsCopy.Log = db.log()
	}

	return db.Database.Migrate(&optsCopy)
}

func (db *DatabaseBuilder) log() logging.Logger {
	if db.Builder.Log != nil {
		return db.Builder.Log
	}

	return defaultLog
}
