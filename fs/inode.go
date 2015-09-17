package fs

import (
	"path"
	"sync"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/koding/fuseklient/transport"
)

// Inode is the generic structure for File and Dir in KodingNetworkFS. It's
// a tree, see Inode#Parent.
type Inode struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	// Parent is the parent, ie. folder that holds this file or directory.
	// This is nil when it's the root Inode. A Inode can only have one parent while
	// a parent can have multiple children.
	Parent *Dir

	// ID is the unique identifier. This is used by Kernel to make requests.
	ID fuseops.InodeID

	// LocalPath is full path on locally mounted folder.
	LocalPath string

	// RemotePath is full path on user VM.
	RemotePath string

	// RWLock protects the fields below which may change
	sync.RWMutex

	// Name is the identifier of file or directory. This is only unique within
	// context of a directory.
	Name string

	// Forgotten indicates if entry is no longer in use. This is required since
	// we don't want to change offsets of other Inode in Dir#EntriesList when a
	// Inode is deleted.
	Forgotten bool

	// Attrs is the list of attributes.
	Attrs fuseops.InodeAttributes
}

// NewRootInode is the required initializer for the root node.
func NewRootInode(t transport.Transport, remotePath, localPath string) *Inode {
	return &Inode{
		Transport:  t,
		Parent:     nil, // root node has no parent
		ID:         fuseops.RootInodeID,
		LocalPath:  localPath,
		RemotePath: remotePath,
		RWMutex:    sync.RWMutex{},
		Name:       "root",
		Forgotten:  false,
		Attrs:      fuseops.InodeAttributes{},
	}
}

func NewInode(p *Dir, name string) *Inode {
	n := &Inode{
		Transport:  p.Transport,
		Parent:     p,
		ID:         p.NodeIDGen.Next(),
		LocalPath:  path.Join(p.LocalPath, name),
		RemotePath: path.Join(p.RemotePath, name),
		RWMutex:    sync.RWMutex{},
		Name:       name,
		Forgotten:  false,
		Attrs:      p.Attrs,
	}

	n.Attrs.Nlink = 0

	return n
}

func (n *Inode) Open() {
	n.Lock()
	n.Attrs.Nlink++
	n.Unlock()
}

func (n *Inode) Release() {
	n.Lock()
	n.Attrs.Nlink = 0
	n.Unlock()
}

func (n *Inode) Forget() {
	n.Lock()
	n.Forgotten = true
	n.Unlock()
}

func (n *Inode) IsForgotten() bool {
	n.RLock()
	defer n.RUnlock()

	return n.Forgotten
}

func (n *Inode) Rename(name string) {
	n.Lock()
	n.Name = name
	n.Unlock()
}

func (n *Inode) GetAttrs() fuseops.InodeAttributes {
	n.RLock()
	defer n.RUnlock()

	return n.Attrs
}

func (n *Inode) SetAttrs(attrs fuseops.InodeAttributes) {
	n.Lock()
	n.Attrs = attrs
	n.Unlock()
}

func (n *Inode) GetID() fuseops.InodeID {
	n.RLock()
	defer n.RUnlock()

	return n.ID
}

///// Helpers

func (n *Inode) updateAttrsFromRemote() error {
	attrs, err := n.getAttrsFromRemote()
	if err != nil {
		return err
	}

	n.Lock()
	n.Attrs = attrs
	n.Unlock()

	return nil
}

func (n *Inode) getAttrsFromRemote() (fuseops.InodeAttributes, error) {
	var attrs fuseops.InodeAttributes

	req := struct{ Path string }{n.RemotePath}
	res := transport.FsGetInfoRes{}
	if err := n.Trip("fs.getInfo", req, &res); err != nil {
		return attrs, err
	}

	if !res.Exists {
		return attrs, fuse.ENOENT
	}

	attrs.Size = uint64(res.Size)
	attrs.Mode = res.Mode

	return attrs, nil
}
