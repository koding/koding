package fs

import (
	"errors"
	"os"
	"path"
	"path/filepath"
	"time"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/transport"
)

var (
	ErrNotADir  = errors.New("Node is a not directory.")
	ErrNotAFile = errors.New("Node is a not file.")
)

type entry struct {
	Offset fuseops.DirOffset
	Name   string
	Type   fuseutil.DirentType
	Mode   os.FileMode
	Size   uint64
	Time   time.Time
}

type Dir struct {
	// Node is generic structure that contains commonality between File and Dir.
	*Inode

	// NodeIDGen is responsible for generating ids for newly created nodes.
	NodeIDGen *NodeIDGen

	////// Node#RWLock protects the fields below.

	// Entries contains list of files and directories that belong to this Node.
	// This list of empty if Node is a file.
	Entries []fuseutil.Dirent

	// EntriesList contains list of files and directories that belong to this Node
	// mapped by entry name for easy lookup. This list of empty if Node is a file.
	EntriesList map[string]Node
}

func NewDir(n *Inode, idGen *NodeIDGen) *Dir {
	return &Dir{
		Inode:       n,
		NodeIDGen:   idGen,
		Entries:     []fuseutil.Dirent{},
		EntriesList: map[string]Node{},
	}
}

func (d *Dir) ReadEntries(offset fuseops.DirOffset) ([]fuseutil.Dirent, error) {
	d.RLock()
	var entries = d.Entries
	d.RUnlock()

	if len(entries) == 0 {
		if err := d.updateEntriesFromRemote(); err != nil {
			return nil, err
		}
		entries = d.Entries
	}

	if offset > fuseops.DirOffset(len(entries)) {
		return nil, fuse.EIO
	}

	var liveEntries []fuseutil.Dirent
	for _, e := range entries[offset:] {
		if e.Type != fuseutil.DT_Unknown {
			liveEntries = append(liveEntries, e)
		}
	}

	return liveEntries, nil
}

func (d *Dir) FindEntry(name string) (Node, error) {
	return d.findEntry(name)
}

func (d *Dir) FindEntryFile(name string) (*File, error) {
	n, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	f, ok := n.(*File)
	if !ok {
		return nil, ErrNotAFile
	}

	return f, nil
}

func (d *Dir) FindEntryDir(name string) (*Dir, error) {
	n, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	d, ok := n.(*Dir)
	if !ok {
		return nil, ErrNotADir
	}

	return d, nil
}

func (d *Dir) CreateEntryDir(name string, mode os.FileMode) (*Dir, error) {
	if _, err := d.findEntry(name); err != fuse.ENOENT {
		return nil, fuse.EEXIST
	}

	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      filepath.Join(d.RemotePath, name),
		Recursive: true,
	}
	var res bool
	if err := d.Trip("fs.createDirectory", req, &res); err != nil {
		return nil, err
	}

	e := &entry{
		Name: name,
		Type: fuseutil.DT_Directory,
		Mode: d.Attrs.Mode,
	}

	child, err := d.initializeChild(e)
	if err != nil {
		return nil, err
	}

	dir, ok := child.(*Dir)
	if !ok {
		return nil, ErrNotADir
	}

	dir.Attrs.Mode = mode

	return dir, nil
}

func (d *Dir) CreateEntryFile(name string, mode os.FileMode) (*File, error) {
	if _, err := d.findEntry(name); err != fuse.ENOENT {
		return nil, fuse.EEXIST
	}

	e := &entry{
		Name: name,
		Type: fuseutil.DT_File,
		Mode: d.Attrs.Mode,
	}

	child, err := d.initializeChild(e)
	if err != nil {
		return nil, err
	}

	file, ok := child.(*File)
	if !ok {
		return nil, ErrNotAFile
	}

	file.Attrs.Mode = mode

	if err := file.Create(); err != nil {
		return file, err
	}

	return file, nil
}

func (d *Dir) MoveEntry(oldName, newName string, newDir *Dir) error {
	child, err := d.findEntry(oldName)
	if err != nil {
		return err
	}

	if err := d.removeChild(oldName); err != nil {
		return err
	}

	req := struct{ OldPath, NewPath string }{
		OldPath: filepath.Join(d.RemotePath, oldName),
		NewPath: filepath.Join(newDir.RemotePath, newName),
	}
	var res bool

	if err := d.Trip("fs.rename", req, res); err != nil {
		return err
	}

	e := &entry{
		Name: newName,
		Type: child.GetType(),
		Mode: child.GetAttrs().Mode,
	}

	_, err = newDir.initializeChild(e)

	return err
}

func (d *Dir) RemoveEntry(name string) (Node, error) {
	entry, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      path.Join(d.RemotePath, name),
		Recursive: true,
	}
	var res bool
	if err := d.Trip("fs.remove", req, &res); err != nil {
		return nil, err
	}

	if err := d.removeChild(name); err != nil {
		return nil, err
	}

	return entry, nil
}

func (d *Dir) GetType() fuseutil.DirentType {
	return fuseutil.DT_Directory
}

func (d *Dir) IsADir() bool {
	return true
}

///// Helpers

func (d *Dir) findEntry(name string) (Node, error) {
	d.RLock()
	defer d.RUnlock()

	child, ok := d.EntriesList[name]
	if !ok {
		return nil, fuse.ENOENT
	}

	return child, nil
}

func (d *Dir) updateEntriesFromRemote() error {
	d.Lock()
	defer d.Unlock()

	entries, err := d.getEntriesFromRemote()
	if err != nil {
		return err
	}

	d.Entries = []fuseutil.Dirent{}
	d.EntriesList = map[string]Node{}

	for _, e := range entries {
		if _, err := d.initializeChild(e); err != nil {
			return err
		}
	}

	return nil
}

func (d *Dir) getEntriesFromRemote() ([]*entry, error) {
	req := struct{ Path string }{d.RemotePath}
	res := transport.FsReadDirectoryRes{}
	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	var entries []*entry
	for _, file := range res.Files {
		var fileType fuseutil.DirentType = fuseutil.DT_File
		if file.IsDir {
			fileType = fuseutil.DT_Directory
		}

		e := &entry{
			Name: file.Name,
			Type: fileType,
			Mode: file.Mode,
			Size: uint64(file.Size),
			Time: file.Time,
		}

		entries = append(entries, e)
	}

	return entries, nil
}

func (d *Dir) initializeChild(e *entry) (Node, error) {
	var t = e.Time
	if t.IsZero() {
		t = time.Now()
	}

	attrs := fuseops.InodeAttributes{
		Size:   e.Size,
		Uid:    d.Attrs.Uid,
		Gid:    d.Attrs.Gid,
		Mode:   e.Mode,
		Atime:  t,
		Mtime:  t,
		Ctime:  t,
		Crtime: t,
	}

	n := NewInode(d, e.Name)
	n.Attrs = attrs

	dirEntry := fuseutil.Dirent{
		Offset: fuseops.DirOffset(len(d.Entries)) + 1, // offset is 1 indexed
		Inode:  n.ID,
		Name:   e.Name,
		Type:   e.Type,
	}

	d.Entries = append(d.Entries, dirEntry)

	var dt Node
	switch e.Type {
	case fuseutil.DT_Directory:
		dt = NewDir(n, d.NodeIDGen)
	case fuseutil.DT_File:
		dt = NewFile(n)
	default:
	}

	d.EntriesList[e.Name] = dt

	return dt, nil
}

func (d *Dir) removeChild(name string) error {
	d.Lock()
	defer d.Unlock()

	listEntry, ok := d.EntriesList[name]
	if !ok {
		return fuse.ENOENT
	}

	listEntry.Forget()

	delete(d.EntriesList, name)

	for index, mapEntry := range d.Entries {
		if mapEntry.Name == name {
			mapEntry.Type = fuseutil.DT_Unknown
			d.Entries[index] = mapEntry
		}
	}

	return nil
}
