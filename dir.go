package main

import (
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"golang.org/x/net/context"
)

type Dir struct {
	*Node

	// Entries contains list of files and directories belong to this Dir.
	Entries []*Node

	// fuseEntries contains cache for `fs.ReadDirAll` request to Klient.
	// TODO: need a better name
	fuseEntries []fuse.Dirent
}

func NewDir(n *Node) *Dir {
	return &Dir{Node: n, Entries: []*Node{}}
}

// Lookup returns file or dir if exists; fuse.EEXIST if not. Required by Fuse.
func (d *Dir) Lookup(ctx context.Context, name string) (fs.Node, error) {
	d.RLock()
	defer d.RUnlock()

	n := NewNode(d.Transport)
	n.Name = name
	n.InternalPath = filepath.Join(d.InternalPath, name)
	n.ExternalPath = filepath.Join(d.ExternalPath, name)

	// TODO: how to deal with resource files
	if strings.HasPrefix(name, "._") {
		return n, nil
	}

	defer debug(time.Now(), "Lookup="+name)

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
		return NewDir(n), nil
	}

	return NewDir(n), nil
}

// ReadDirAll returns metadata for files and directories. Required by Fuse.
func (d *Dir) ReadDirAll(ctx context.Context) ([]fuse.Dirent, error) {
	defer debug(time.Now(), "ReadDirAll="+d.Name)

	d.RLock()
	defer d.RUnlock()

	if len(d.fuseEntries) != 0 {
		return d.fuseEntries, nil
	}

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

	d.fuseEntries = dirents

	return dirents, nil
}
