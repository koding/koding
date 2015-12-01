package fuseklient

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"time"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/transport"
)

type tempEntry struct {
	Offset fuseops.DirOffset
	Name   string
	Type   fuseutil.DirentType
	Mode   os.FileMode
	Size   uint64
	Time   time.Time
}

type Dir struct {
	// Node is generic structure that contains commonality between File and Dir.
	*Entry

	// IDGen is responsible for generating ids for newly created nodes.
	IDGen *IDGen

	////// Entry#RWLock protects the fields below.

	// Entries contains list of files and directories that belong to this
	// directory.
	//
	// Note even if an entry is deleted, it'll still be in this list however
	// the deleted entry's type will be set to `fuseutil.DT_Unknown`, so requests
	// to return entries can be filtered. This is done so we set proper offset
	// position for newly created entries. In other words once an entry is given
	// an offset position, it should maintain that position throughout.
	Entries []fuseutil.Dirent

	// EntriesList contains list of files and directories that belong to this
	// directory mapped by entry name for easy lookup.
	EntriesList map[string]Node
}

func NewDir(e *Entry, idGen *IDGen) *Dir {
	return &Dir{
		Entry:       e,
		IDGen:       idGen,
		Entries:     []fuseutil.Dirent{},
		EntriesList: map[string]Node{},
	}
}

///// Directory operations

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

	// return err if offset is greather than list of entries
	if offset > fuseops.DirOffset(len(entries)) {
		return nil, fuse.EIO
	}

	// filter by entries whose type is not to set fuse.DT_Unknown
	var liveEntries []fuseutil.Dirent
	for _, e := range entries[offset:] {
		if e.Type != fuseutil.DT_Unknown {
			liveEntries = append(liveEntries, e)
		}
	}

	return liveEntries, nil
}

func (d *Dir) FindEntryDir(name string) (*Dir, error) {
	n, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	d, ok := n.(*Dir)
	if !ok {
		return nil, fuse.ENOTDIR
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

	e := &tempEntry{
		Name: name,
		Type: fuseutil.DT_Directory,
		Mode: d.Attrs.Mode,
	}

	child, err := d.initializeChild(e)
	if err != nil {
		return nil, err
	}

	dir, _ := child.(*Dir)
	dir.Attrs.Mode = mode

	return dir, nil
}

///// File operations

func (d *Dir) FindEntryFile(name string) (*File, error) {
	n, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	f, ok := n.(*File)
	if !ok {
		return nil, fuse.EIO
	}

	return f, nil
}

func (d *Dir) CreateEntryFile(name string, mode os.FileMode) (*File, error) {
	if _, err := d.findEntry(name); err != fuse.ENOENT {
		return nil, fuse.EEXIST
	}

	e := &tempEntry{
		Name: name,
		Type: fuseutil.DT_File,
		Mode: d.Attrs.Mode,
	}

	child, err := d.initializeChild(e)
	if err != nil {
		return nil, err
	}

	file, _ := child.(*File)
	file.Attrs.Mode = mode

	if err := file.Create(); err != nil {
		return file, err
	}

	return file, nil
}

///// File and Directory operations

func (d *Dir) FindEntry(name string) (Node, error) {
	return d.findEntry(name)
}

func (d *Dir) MoveEntry(oldName, newName string, newDir *Dir) (Node, error) {
	child, err := d.findEntry(oldName)
	if err != nil {
		return nil, err
	}

	removedEntry, err := d.removeChild(oldName)
	if err != nil {
		return nil, err
	}

	req := struct{ OldPath, NewPath string }{
		OldPath: filepath.Join(d.RemotePath, oldName),
		NewPath: filepath.Join(newDir.RemotePath, newName),
	}
	var res bool

	if err := d.Trip("fs.rename", req, res); err != nil {
		return nil, err
	}

	e := &tempEntry{
		Name: newName,
		Type: child.GetType(),
		Mode: child.GetAttrs().Mode,
	}

	newEntry, err := newDir.initializeChild(e)
	if err != nil {
		return nil, err
	}

	switch child.GetType() {
	case fuseutil.DT_Directory:
		dir1 := removedEntry.(*Dir)
		dir2 := newEntry.(*Dir)

		dir2.Entries = dir1.Entries
		dir2.EntriesList = dir1.EntriesList
		dir2.Entry.Parent = newDir
	case fuseutil.DT_File:
		file2 := newEntry.(*File)
		file2.Entry.Parent = newDir

		if err := file2.updateContentFromRemote(); err != nil {
			return nil, nil
		}
	}

	return newEntry, nil
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

	if _, err := d.removeChild(name); err != nil {
		return nil, err
	}

	return entry, nil
}

///// Node interface

func (d *Dir) GetType() fuseutil.DirentType {
	return fuseutil.DT_Directory
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

func newTempEntry(file transport.FsGetInfoRes) *tempEntry {
	var fileType fuseutil.DirentType = fuseutil.DT_File
	if file.IsDir {
		fileType = fuseutil.DT_Directory
	}

	return &tempEntry{
		Name: file.Name,
		Type: fileType,
		Mode: file.Mode,
		Size: uint64(file.Size),
		Time: file.Time,
	}
}

func (d *Dir) getEntriesFromRemote() ([]*tempEntry, error) {
	req := struct{ Path string }{d.RemotePath}
	res := transport.FsReadDirectoryRes{}
	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	var entries []*tempEntry
	for _, file := range res.Files {
		e := newTempEntry(file)
		entries = append(entries, e)
	}

	return entries, nil
}

func (d *Dir) initializeChild(e *tempEntry) (Node, error) {
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

	n := NewEntry(d, e.Name)
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
		dt = NewDir(n, d.IDGen)
	case fuseutil.DT_File:
		dt = NewFile(n)
	default:
		return nil, fmt.Errorf("Unknown file type: %v", e.Type)
	}

	d.EntriesList[e.Name] = dt

	return dt, nil
}

func (d *Dir) removeChild(name string) (Node, error) {
	listEntry, err := d.findEntry(name)
	if err != nil {
		return nil, err
	}

	d.Lock()
	defer d.Unlock()

	listEntry.Forget()

	delete(d.EntriesList, name)

	for index, mapEntry := range d.Entries {
		if mapEntry.Name == name {
			mapEntry.Type = fuseutil.DT_Unknown
			d.Entries[index] = mapEntry
		}
	}

	return listEntry, nil
}

func (d *Dir) reset() {
	d.Lock()
	defer d.Unlock()

	d.Entries = []fuseutil.Dirent{}
	d.EntriesList = map[string]Node{}
}
