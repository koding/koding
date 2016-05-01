package errormessages

var (
	// InvalidCLIOption is a generic message to print when two options cannot be
	// used together.
	InvalidCLIOption = "Invalid Option: %s cannot be used with UseSync"

	// FishDefaultPathMissing is used when the installation path for fish autocomplete
	// cannot be found, and was not supplied.
	FishDefaultPathMissing = `Error: Unable to assert default fish path.
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
)
