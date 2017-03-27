package fs

import (
	"errors"
)

// AbsRequest defines a request for absolute path representation.
type AbsRequest struct {
	Path string `json:"path"` // Path to requested file or directory.
}

// AbsResponse contains absolute path representation response.
type AbsResponse struct {
	AbsPath string `json:"absPath"` // Absolute representation of requested path.
	IsDir   bool   `json:"isDir"`   // Set to true when path is a directory.
	Exist   bool   `json:"exist"`   // Set to true when path exists.
}

// Abs converts path to its absolute representation.
func Abs(req *AbsRequest) (*AbsResponse, error) {
	if req == nil {
		return nil, errors.New("invalid empty request")
	}

	absPath, isDir, exist, err := DefaultFS.Abs(req.Path)
	if err != nil {
		return nil, err
	}

	return &AbsResponse{
		AbsPath: absPath,
		IsDir:   isDir,
		Exist:   exist,
	}, nil
}
