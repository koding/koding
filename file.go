package main

import (
	"time"

	"golang.org/x/net/context"
)

type File struct{ *Node }

// ReadAll returns the entire file. Required by Fuse.
func (f *File) ReadAll(ctx context.Context) ([]byte, error) {
	defer debug(time.Now(), "File="+f.Name)

	f.RLock()
	defer f.RUnlock()

	req := struct{ Path string }{f.ExternalPath}
	res := fsReadFileRes{}

	if err := f.Trip("fs.readFile", req, &res); err != nil {
		return []byte{}, err
	}

	return res.Content, nil
}
