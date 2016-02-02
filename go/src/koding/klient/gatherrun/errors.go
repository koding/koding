package gatherrun

import "errors"

var (
	ErrErrorIsEmpty   = errors.New("expect error, got empty")
	ErrFolderNotFound = errors.New("folder not found")
)
