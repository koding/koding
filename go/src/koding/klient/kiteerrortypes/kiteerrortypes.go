// A series of kite error type constants. Because the usage of the kite error
// types can be used anywhere, these types should never be changed.
// Incosistencies in formatting likely means that the type came from somewhere
// else. New types should adhere to camelcase.
//
// Leave existing cases as is!
//
package kiteerrortypes

const (
	//
	// Kite error types not generated from Klient:
	//

	AuthenticationError = "authenticationError"

	//
	// Kite error types generated from klient:
	//

	MachineNotFound           = "MachineNotFound"
	MachineUnreachable        = "MachineUnreachable"
	AuthErrTokenIsExpired     = "AuthErrTokenIsExpired"
	AuthErrTokenIsNotValidYet = "AuthErrTokenIsNotValidYet"
	MissingArgument           = "MissingArgument"

	// Returned from a machine's CheckValid() method when the machine is missing a
	// critical field. Ie, the machine was loaded from the database but has
	// not yet been populated via GetKites. For more information, see
	// Machine.CheckValid method docstring.
	MachineNotValidYet = "MachineNotValidYet"

	// DialingFailed is the kite.Error.Type used for errors encountered when
	// dialing the remote.
	DialingFailed = "dialing failed"

	// MountNotFound is the kite.Error.Type used for errors encountered when
	// the mount name given cannot be found.
	MountNotFound = "mount not found"

	// SystemUnmountFailed is the Kite Error Type used when either the unmounter
	// fails, or generic (non-instanced) unmount fails.
	SystemUnmountFailed = "system-unmount-failed"

	// SubNotFound is used in klient/client.ErrSubNotFound
	SubNotFound = "SubNotFound"

	// RemotePathDoesNotExist is used in klient/remote/mount.Mounter
	RemotePathDoesNotExist = "RemotePathDoesNotExist"

	// MachineActionIsLocked is used when the requested actions (such as mount related
	// actions) are locked.
	MachineActionIsLocked = "MachineActionIsLocked"

	// MachineDuplicate is used if a machine was attempted to be added to
	// the machines struct, but it is not unique. Ie, another machine shares field
	// values with the given machine that should be unique.
	MachineDuplicate = "MachineDuplicate"

	// MachineAlreadyAdded is used if a machine instance was added to a Machines
	// struct twice.
	MachineAlreadyAdded = "MachineAlreadyAdded"

	// Returned from a klient/command.Command when running the command fails in a
	// non-exit status way.
	ProcessError = "ProcessError"

	// Returned from klient/client/Publish when there are no listeners for the given
	// event.
	NoSubscribers = "NoSubscribers"
)
