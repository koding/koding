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

	// EntriesList contains list of files and directories belong to this Dir.
	EntriesList map[string]*Node

	// fuseEntries contains cache for `fs.ReadDirAll` request to Klient.
	// TODO: need a better name
	FuseEntries []fuse.Dirent
}

func NewDir(n *Node) *Dir {
	return &Dir{Node: n, EntriesList: map[string]*Node{}}
}

// Lookup returns file or dir if exists; fuse.EEXIST if not. Required by Fuse.
// TODO: return fuse.EEXIST if entry doesn't exist in user VM.
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

	// debug should almost be the first statement, but to prevent spamming of
	// resource file lookups, this call is moved here
	defer debug(time.Now(), "Lookup="+name)

	if n, ok := d.EntriesList[name]; ok {
		if n.DirentType == fuse.DT_Dir {
			return NewDir(n), nil
		}

		return &File{n}, nil
	}

	req := struct{ Path string }{n.ExternalPath}
	res := fsGetInfoRes{}

	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	n.Name = path.Base(n.ExternalPath)
	n.attr.Size = uint64(res.Size)
	n.attr.Mode = os.FileMode(res.Mode)

	// TODO: set node in Dir#EntriesList?

	if res.IsDir {
		return NewDir(n), nil
	}

	return &File{n}, nil
}

// ReadDirAll returns metadata for files and directories. Required by Fuse.
func (d *Dir) ReadDirAll(ctx context.Context) ([]fuse.Dirent, error) {
	defer debug(time.Now(), "ReadDirAll="+d.Name)

	d.Lock()
	defer d.Unlock()

	if len(d.FuseEntries) != 0 {
		return d.FuseEntries, nil
	}

	req := struct{ Path string }{d.ExternalPath}
	res := fsReadDirectoryRes{}

	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	var dirents []fuse.Dirent
	for _, file := range res.Files {
		ent := fuse.Dirent{Name: file.Name, Type: fuse.DT_File}
		if file.IsDir {
			ent.Type = fuse.DT_Dir
		}
		dirents = append(dirents, ent)

		n := NewNode(d.Transport)
		n.Name = file.Name
		n.InternalPath = filepath.Join(d.InternalPath, file.Name)
		n.ExternalPath = filepath.Join(d.ExternalPath, file.Name)
		n.DirentType = ent.Type
		n.attr.Size = uint64(file.Size)
		n.attr.Mode = os.FileMode(file.Mode)

		d.EntriesList[file.Name] = n
	}

	d.FuseEntries = dirents

	return dirents, nil
}
