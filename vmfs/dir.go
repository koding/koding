package vmfs

import (
	"os"
	"path/filepath"
	"strings"
	"time"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"golang.org/x/net/context"

	"github.com/koding/fuseklient/transport"
)

type Dir struct {
	*Node

	// Parent is pointer to Dir that holds this Dir. Each File/Dir has single
	// parent; a parent can have multiple children.
	Parent *Dir

	// EntriesList contains list of files and directories belong to this Dir.
	// This is used to speed up individual entry lookups.
	EntriesList map[string]*Node

	// EntriesList contains list of files and directories belong to this Dir.
	Entries []fuse.Dirent
}

func NewDir(n *Node) *Dir {
	return &Dir{Node: n, EntriesList: map[string]*Node{}}
}

// Lookup returns file or dir if exists. Required by Fuse.
func (d *Dir) Lookup(ctx context.Context, name string) (fs.Node, error) {
	d.RLock()
	defer d.RUnlock()

	n := NewNode(d, name)

	// TODO: how to deal with resource files
	if strings.HasPrefix(name, "._") {
		return n, nil
	}

	// debug should almost be the first statement, but to prevent spamming of
	// resource file lookups, this call is moved here
	defer debug(time.Now(), "Lookup="+name)

	// get entry from cache, return if it exists
	if n, ok := d.EntriesList[name]; ok {
		if n.DirentType == fuse.DT_Dir {
			return NewDir(n), nil
		}

		return &File{Parent: d, Node: n}, nil
	}

	res, err := n.getRemoteAttr()
	if err != nil {
		return nil, err
	}

	n.attr.Size = uint64(res.Size)
	n.attr.Mode = os.FileMode(res.Mode)

	// TODO: cache node in Dir#EntriesList and Dir#fuseEntries?

	if res.IsDir {
		return NewDir(n), nil
	}

	return &File{Parent: d, Node: n}, nil
}

// ReadDirAll returns metadata for files and directories. Required by Fuse.
//
// TODO: this method is called way too many times in a short interval.
func (d *Dir) ReadDirAll(ctx context.Context) ([]fuse.Dirent, error) {
	defer debug(time.Now(), "Dir="+d.Name)

	d.RLock()
	entries := d.Entries
	d.RUnlock()

	if len(entries) != 0 {
		return entries, nil
	}

	return d.readDirAll()
}

// Create create new File. Required by Fuse.
func (d *Dir) Create(ctx context.Context, req *fuse.CreateRequest, resp *fuse.CreateResponse) (fs.Node, fs.Handle, error) {
	n := NewNode(d, req.Name)
	f := &File{Parent: d, Node: n}

	var err error
	if _, err = n.getRemoteAttr(); err != nil && err != fuse.ENOENT {
		return nil, nil, err
	}

	// only write if file doesn't already exist
	if err == fuse.ENOENT {
		if err := f.write([]byte{}); err != nil {
			return nil, nil, err
		}
	}

	if err := d.invalidateCache(req.Name); err != nil {
		return nil, nil, err
	}

	return f, f, nil
}

// Mkdir creates new directory under inside Dir. Required by Fuse.
func (d *Dir) Mkdir(ctx context.Context, req *fuse.MkdirRequest) (fs.Node, error) {
	defer debug(time.Now(), "Dir="+req.Name)

	path := filepath.Join(d.RemotePath, req.Name)
	treq := struct {
		Path      string
		Recursive bool
	}{
		Path:      path,
		Recursive: true,
	}
	var tres bool
	if err := d.Trip("fs.createDirectory", treq, &tres); err != nil {
		return nil, err
	}

	if err := d.invalidateCache(req.Name); err != nil {
		return nil, err
	}

	// TODO: make `fs.createDirectory` to return folder info in creation
	n := NewNode(d, req.Name)
	res, err := n.getRemoteAttr()
	if err != nil {
		return nil, err
	}

	n.attr.Size = uint64(res.Size)
	n.attr.Mode = os.FileMode(res.Mode)

	return &Dir{Parent: d, Node: n}, nil
}

// Remove deletes File or Dir. Required by Fuse.
func (d *Dir) Remove(ctx context.Context, req *fuse.RemoveRequest) error {
	defer debug(time.Now(), "Dir="+req.Name)

	path := filepath.Join(d.RemotePath, req.Name)
	treq := struct {
		Path      string
		Recursive bool
	}{
		Path:      path,
		Recursive: true,
	}
	var tres bool
	if err := d.Trip("fs.remove", treq, &tres); err != nil {
		return err
	}

	return d.invalidateCache(req.Name)
}

// Rename changes name of File or Dir. Required by Fuse.
func (d *Dir) Rename(ctx context.Context, req *fuse.RenameRequest, newDir fs.Node) error {
	defer debug(time.Now(), "OldPath="+req.OldName, "NewPath="+req.NewName)

	path := d.RemotePath
	treq := struct{ OldPath, NewPath string }{
		OldPath: filepath.Join(path, req.OldName),
		NewPath: filepath.Join(path, req.NewName),
	}
	var tres bool
	if err := d.Trip("fs.rename", treq, &tres); err != nil {
		return err
	}

	return d.invalidateCache(req.OldName)
}

// readDirAll asks Transport for entries and saves them for future lookups.
func (d *Dir) readDirAll() ([]fuse.Dirent, error) {
	d.Lock()
	defer d.Unlock()

	req := struct{ Path string }{d.RemotePath}
	res := transport.FsReadDirectoryRes{}
	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	d.EntriesList = map[string]*Node{}

	var dirents []fuse.Dirent
	for _, file := range res.Files {
		ent := fuse.Dirent{Name: file.Name, Type: fuse.DT_File}
		if file.IsDir {
			ent.Type = fuse.DT_Dir
		}
		dirents = append(dirents, ent)

		n := NewNode(d, file.Name)
		n.DirentType = ent.Type
		n.attr.Size = uint64(file.Size)
		n.attr.Mode = os.FileMode(file.Mode)

		d.EntriesList[file.Name] = n
	}

	d.Entries = dirents

	return dirents, nil
}

// invalidateCache removes cache, which will trigger lookup in Transport on next
// request to be used on write operations; to be used in write operations.
//
// TODO: be smarter about invalidating cache, ie delete entry and do lookup.
func (d *Dir) invalidateCache(entry string) error {
	_, err := d.readDirAll()
	return err
}
