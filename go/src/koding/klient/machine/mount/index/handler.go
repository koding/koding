package index

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// Request defines cached index operations that are requested from
// client to remote machine.
type Request struct {
	Path string `json:"remotePath"` // Path to the folder we want to mount.
}

// HeadResponse contains the basic info about requested index.
type HeadResponse struct {
	AbsPath  string `json:"absPath"`  // Absolute representation of requested path.
	Count    int    `json:"count"`    // Number of all files stored in index.
	DiskSize int64  `json:"diskSize"` // The byte size of all files stored in index.
}

// Head gives the basic information about requested directory index.
func Head(req *Request) (*HeadResponse, error) {
	if req == nil {
		return nil, errors.New("invalid empty request")
	}

	absPath, err := preparePath(req.Path)
	if err != nil {
		return nil, err
	}

	count, diskSize, err := (&Cached{}).HeadCachedIndex(absPath)
	if err != nil {
		return nil, fmt.Errorf("remote path index error: %s", err)
	}

	return &HeadResponse{
		AbsPath:  absPath,
		Count:    count,
		DiskSize: diskSize,
	}, nil
}

// GetResponse stores the index of requested directory.
type GetResponse struct {
	Index *Index `json:"index"`
}

// Get gets the complete index of requested directory.
func Get(req *Request) (*GetResponse, error) {
	if req == nil {
		return nil, errors.New("invalid empty request")
	}

	absPath, err := preparePath(req.Path)
	if err != nil {
		return nil, err
	}

	idx, err := (&Cached{}).GetCachedIndex(absPath)
	if err != nil {
		return nil, fmt.Errorf("remote path index error: %s", err)
	}

	return &GetResponse{
		Index: idx,
	}, nil
}

// preparePath performs basic checks and makes a given path usable for local
// file system.
func preparePath(path string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("remote path format is invalid: %s", err)
	}

	info, err := os.Stat(absPath)
	if os.IsNotExist(err) {
		return "", errors.New("remote path does not exist")
	} else if err != nil {
		return "", fmt.Errorf("cannot stat remote path: %s", err)
	}

	if !info.IsDir() {
		return "", errors.New("remote path is not a directory")
	}

	return absPath, nil
}
