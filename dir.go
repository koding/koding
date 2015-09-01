package main

import (
	"os"
	"path"
	"path/filepath"
	"time"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"golang.org/x/net/context"
)

type Dir struct {
	*Node
}

// Lookup returns file or dir if exists; fuse.EEXIST if not. Required by Fuse.
func (d *Dir) Lookup(ctx context.Context, name string) (fs.Node, error) {
	defer debug(time.Now(), "Lookup="+name)

	d.RLock()
	defer d.RUnlock()

	n := NewNode(d.Transport)
	n.Name = name
	n.InternalPath = filepath.Join(d.InternalPath, name)
	n.ExternalPath = filepath.Join(d.ExternalPath, name)

	req := struct{ Path string }{n.ExternalPath}
	res := fsGetInfoRes{}

	// TODO: lookup name in cache, ask Klient only if not in cache
	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	n.Name = path.Base(n.ExternalPath)
	n.attr.Size = uint64(res.Size)
	n.attr.Mode = os.FileMode(res.Mode)

	if res.IsDir {
		return &Dir{n}, nil
	}

	return &File{n}, nil
}

// ReadDirAll returns metadata for files and directories. Required by Fuse.
func (d *Dir) ReadDirAll(ctx context.Context) ([]fuse.Dirent, error) {
	defer debug(time.Now(), "ReadDirAll="+d.Name)

	d.RLock()
	defer d.RUnlock()

	req := struct{ Path string }{d.ExternalPath}
	res := fsReadDirectoryRes{}

	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	// TODO: cache these results
	var dirents []fuse.Dirent
	for _, file := range res.Files {
		ent := fuse.Dirent{Name: file.Name, Type: fuse.DT_File}
		if file.IsDir {
			ent.Type = fuse.DT_Dir
		}
		dirents = append(dirents, ent)
	}

	return dirents, nil
}
