package fuseklient

import (
	"path/filepath"
	"sync"

	"koding/fuseklient/transport"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
)

// Entry is the generic structure for File and Dir in KodingNetworkFS. It's
// a tree, see Entry#Parent.
type Entry struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	// Parent is the parent, ie. folder that holds this file or directory.
	// This is nil when it's the root entry. A Entry can only have one parent while
	// a parent can have multiple children.
	Parent *Dir

	// ID is the unique identifier. This is used by Kernel to make requests.
	ID fuseops.InodeID

	// Path is the full path on locally mounted folder. Note it does not contain
	// the remote path prefix, that's in transport.
	Path string

	// Uid is the user id that'll always be used in spite of what remote returns.
	Uid uint32

	// Gid is the group id that'll always be used in spite of what remote returns.
	Gid uint32

	// RWLock protects the fields below which may change
	sync.RWMutex

	// Name is the identifier of file or directory. This is only unique within
	// context of a directory.
	Name string

	// Forgotten indicates if entry is no longer in use. This is required since
	// we don't want to change offsets of other Entry in Dir#EntriesList when a
	// Entry is deleted.
	Forgotten bool

	// Attrs is the list of attributes.
	Attrs fuseops.InodeAttributes
}

// NewRootEntry is the required initializer for the root entry.
func NewRootEntry(t transport.Transport, path string) *Entry {
	return &Entry{
		Transport: t,
		Parent:    nil, // root entry has no parent
		ID:        fuseops.RootInodeID,
		Path:      path,
		RWMutex:   sync.RWMutex{},
		Name:      "root",
		Forgotten: false,
		Attrs:     fuseops.InodeAttributes{},
	}
}

// NewEntry is the required initializer for Entry.
func NewEntry(p *Dir, name string) *Entry {
	e := &Entry{
		Transport: p.Transport,
		Parent:    p,
		ID:        p.IDGen.Next(),
		Path:      filepath.Join(p.Path, name),
		RWMutex:   sync.RWMutex{},
		Name:      name,
		Forgotten: false,
		Attrs:     p.Attrs,
	}

	e.Attrs.Nlink = 0

	return e
}

func (e *Entry) Open() {
	e.Lock()
	e.Attrs.Nlink++
	e.Unlock()
}

func (e *Entry) Release() {
	e.Lock()
	e.Attrs.Nlink = 0
	e.Unlock()
}

func (e *Entry) Forget() {
	e.Lock()
	e.Forgotten = true
	e.Unlock()
}

func (e *Entry) IsForgotten() bool {
	e.RLock()
	defer e.RUnlock()

	return e.Forgotten
}

func (e *Entry) Rename(name string) {
	e.Lock()
	e.Name = name
	e.Unlock()
}

func (e *Entry) GetAttrs() fuseops.InodeAttributes {
	e.RLock()
	defer e.RUnlock()

	return e.Attrs
}

func (e *Entry) SetAttrs(attrs fuseops.InodeAttributes) {
	e.Lock()
	e.Attrs = attrs
	e.Unlock()
}

func (e *Entry) GetID() fuseops.InodeID {
	e.RLock()
	defer e.RUnlock()

	return e.ID
}

func (e *Entry) UpdateAttrsFromRemote() error {
	e.Lock()
	defer e.Unlock()

	attrs, err := e.getAttrsFromRemote()
	if err != nil {
		return err
	}

	e.Attrs = attrs

	return nil
}

///// Helpers

func (e *Entry) getAttrsFromRemote() (fuseops.InodeAttributes, error) {
	var attrs fuseops.InodeAttributes

	res, err := e.Transport.GetInfo(e.Name)
	if err != nil {
		return attrs, err
	}

	if !res.Exists {
		return attrs, fuse.ENOENT
	}

	attrs.Size = uint64(res.Size)
	attrs.Mode = res.Mode
	attrs.Uid = e.Uid
	attrs.Gid = e.Gid

	return attrs, nil
}
