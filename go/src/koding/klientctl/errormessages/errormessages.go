// A series of error messages provided to the end user, with explanations of how
// they are expected to be used.
package errormessages

import "fmt"

var (
	// GenericInternalError is a generic error message. Typically used when we don't
	// want to reveal what exactly went wrong, like confusing implementation details.
	//
	// This is the same as GenericInternalError, but without a customizable message,
	// hence the "NoMsg".
	GenericInternalErrorNoMsg = "Error: Encountered an internal error."

	// InvalidCLIOption is a generic message to print when two options cannot be
	// used together.
	InvalidCLIOption = "Invalid Option: %s cannot be used with UseSync"

	// FishDefaultPathMissing is used when the installation path for fish autocomplete
	// cannot be found, and was not supplied.
	FishDefaultPathMissing = `Error: Unable to find where to install file autocompete.
Please use --fish-dir=your/dir to install fish.`

	// FishDirFailed is used when creating the bash completion directory fails.
	FishDirFailed = `Error: Unable to create fish autocompletion directory.`

	// FishWriteFailed is used when writing the actual fish autocomplete file failed.
	FishWriteFailed = `Error: Unable to write fish autocompletion file.`

	// BashDirFailed is used when creating the bash completion directory fails.
	BashDirFailed = `Error: Unable to create bash autocompletion directory.`

	// BashWriteFailed is used when writing the actual bash autocomplete file failed.
	BashWriteFailed = `Error: Unable to write bash autocompletion file.`

	// BashPermissionError is used when user op fails with perm denied.
	BashPermissionError = `Error: You do not have sufficient permissions to install
bash autocompletions. Please run this command with sudo.`

	// FailedToGetCurrentUser is used when we're unable to get the user.
	FailedToGetCurrentUser = `Error: Unable to get current user`

	// FailedToAppendBashrc is used when we're unable to append to bashrc file.
	FailedToAppendBashrc = `Error: Unable to append to bashrc file.`

	// FailedToChown is used if a chown fails.
	FailedToChown = `Error: Unable to change file ownership to current user.`

	// SyncDirectionRequired is used when the user does not specify a sync direction.
	//
	// Note that Help is also printed after this.
	SyncDirectionRequired = `Error: Sync direction is a required argument.`

	// InvalidSyncDirection is used when the user specifies an option that is not
	// a supported sync direction.
	//
	// Note that Help is also printed after this.
	InvalidSyncDirection = `Error: Invalid sync direction %q.`

	// MachineNotFound is a generic machine not found message.
	MachineNotFound = "Error: Machine not found. Please enter a valid machine name as shown in kd list."

	// MountNotFound is a generic mount not found message.
	MountNotFound = "Error: Mount not found."

	// FailedGetSSHKey is used when we fail to get the ssh key
	FailedGetSSHKey = fmt.Sprintf("Error: Failed to get ssh key.\n")

	// FailedPrefetchFolder is used when remote.cacheFolder fails.
	FailedPrefetchFolder = fmt.Sprintf(
		"Error: Failed to prefetch the requested folder.\n",
	)

	// MachineNotValidYet occurs when the kontrol has not yet returned a client
	// for the given machine. Likely meaning the machine has not been online
	// since klient has last restarted.
	//
	// Since the above DialingRemote error is generic enough, we're just using that
	// for now.
	MachineNotValidYet = fmt.Sprintf(
		`Error: Unable to communicate with the remote machine. Please ensure that the
remote machine is running & accessible and try again.`,
	)

	// CannotSSHManaged is used when the managed machine has a different username
	// than the current user. A temporary error, for a temporary limitation.
	CannotSSHManaged = "Error: Currently unable to ssh into managed machines."

	// RemoteProcessFailed is used when a command was run on the remote, but the
	// process itself failed to execute properly. *Not* an exit code, but more like
	// a no memory.
	//
	// The %s arg is intended to be the full error.
	RemoteProcessFailed = `A requested process on the remote Machine was unable to run properly,
and exited with the following issue:

%s`

	// RemotePathDoesNotExist is printed when the user supplies a directory to mount,
	// that does not exist on the remote side.
	RemotePathDoesNotExist = fmt.Sprintf(
		`Error: The given remote path does not exist on the remote machine.`,
	)

	// FailedToSync is used when remote.cacheFolder fails during kd sync.
	FailedSyncFolder = fmt.Sprintf(
		"Error: Failed to sync the requested folder.",
	)

	// SourceAndDestAreRemote is used when the user entered two remote paths to kd cp.
	//
	// Note that Help is also printed after this.
	SourceAndDestAreRemote = `Error: Both Source and Destination are Remote.
Please provide a remote and a local path.`

	// SourceAndDestAreLocal is used when the user entered two local paths to kd cp.
	//
	// Note that Help is also printed after this.
	SourceAndDestAreLocal = `Error: Both Source and Destination are Local.
Please provide a remote and a local path.`

	// SourceRequired is used when the user does not specify a sync direction.
	//
	// Note that Help is also printed after this.
	SourceRequired = `Error: Copy Source is a required argument.`

	// DestinationRequired is used when the user does not specify a sync direction.
	//
	// Note that Help is also printed after this.
	DestinationRequired = `Error: Copy Destination is a required argument.`
)
