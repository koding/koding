package main

import "golang.org/x/net/context"

type File struct {
	*Node
}

// ReadAll returns the entire file. Required by Fuse.
func (f *File) ReadAll(ctx context.Context) ([]byte, error) {
	return []byte{}, nil
}
