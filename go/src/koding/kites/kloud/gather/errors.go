package gather

import "errors"

var (
	ErrErrorIsEmpty        = errors.New("expect error, got empty")
	ErrScriptsFileNotFound = errors.New("scripts file not found")
	ErrFolderNotFound      = errors.New("folder not found")
)
