package util

import (
	"errors"
	"os"
)

var (
	// DefaultNeverRemovePaths is list of paths that we will never remove since
	// they're too important.
	DefaultNeverRemovePaths = []string{"/", "/home", "~"}

	ErrRestrictedPath = errors.New("Restricted path cannot be removed.")
)

type RemovePath struct {
	IgnorePaths []string
}

func NewRemovePath() *RemovePath {
	return &RemovePath{
		IgnorePaths: DefaultNeverRemovePaths,
	}
}

// RemovePath removes given path if:
//	1. path is not an import path, see NeverRemovePaths
//  2. if path is a folder, it should be empty
func (r *RemovePath) Do(path string) error {
	if path == "" {
		return errors.New("Path is empty.")
	}

	for _, p := range r.IgnorePaths {
		if p == path {
			return ErrRestrictedPath
		}
	}

	// use os.Remove instead of os.RemoveAll since Remove errs out if folder
	// contains entries; we don't want to delete folders with entries.
	if err := os.Remove(path); err != nil {
		return err
	}

	return nil
}
