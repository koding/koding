package main

import (
	"fmt"
	"time"

	"bazil.org/fuse"

	"golang.org/x/net/context"
)

type File struct {
	*Node

	// Parent is pointer to Dir that holds this Dir. Each File/Dir has single
	// parent; a parent can have multiple children.
	Parent *Dir
}

// ReadAll returns the entire file. Required by Fuse.
func (f *File) ReadAll(ctx context.Context) ([]byte, error) {
	var err error
	defer debug(time.Now(), err, "File="+f.Name)

	f.RLock()
	defer f.RUnlock()

	req := struct{ Path string }{f.ExternalPath}
	res := fsReadFileRes{}

	if err = f.Trip("fs.readFile", req, &res); err != nil {
		return []byte{}, err
	}

	return res.Content, nil
}

// Write rewrites all data to file. Required by Fuse.
func (f *File) Write(ctx context.Context, req *fuse.WriteRequest, resp *fuse.WriteResponse) error {
	var err error
	defer debug(time.Now(), err, "File="+f.Name, fmt.Sprintf("ContentLength=%v", len(req.Data)))

	f.Lock()
	defer f.Unlock()

	treq := struct {
		Path    string
		Content []byte
	}{
		Path:    f.ExternalPath,
		Content: req.Data,
	}

	var tres int

	if err = f.Transport.Trip("fs.writeFile", treq, &tres); err != nil {
		return err
	}

	resp.Size = tres

	return f.Parent.invalidateCache(f.Name)
}
