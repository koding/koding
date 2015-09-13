package fs

import (
	"errors"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/transport"
)

var ErrNodeNotFound = errors.New("node does not exist")

// Node is the generic structure for File and Dir in KodingNetworkFS. It's
// a tree, see Node#Parent.
type Node struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	// ID is the unique identifier. This is used by Kernel to make requests.
	ID fuseops.InodeID

	// Parent is the parent, ie. folder that holds this file or directory.
	// This is nil when it's the root Node. A Node can only have one parent while
	// a parent can have multiple child nodes.
	Parent *Node

	// Name is the identifier of file or directory. This is only unique within
	// context of a directory.
	Name string

	// LocalPath is full path on locally mounted folder.
	LocalPath string

	// RemotePath is full path on user VM.
	RemotePath string

	// NodeIDGen is responsible for generating ids for newly created nodes.
	NodeIDGen *NodeIDGen

	// EntryType is the type ie. file or directory.
	EntryType fuseutil.DirentType

	// RWLock protects the fields below.
	sync.RWMutex

	// Attrs is the list of attributes.
	Attrs fuseops.InodeAttributes

	// Entries contains list of files and directories that belong to this Node.
	// This list of empty if Node is a file.
	Entries []fuseutil.Dirent

	// EntriesList contains list of files and directories that belong to this Node
	// mapped by entry name for easy lookup. This list of empty if Node is a file.
	EntriesList map[string]*Node
}

// NewNode is the required initializer for Node. This only should be used when
// initializing the root Node.
func NewNode(t transport.Transport, idGen *NodeIDGen) *Node {
	return &Node{
		Transport:   t,
		NodeIDGen:   idGen,
		RWMutex:     sync.RWMutex{},
		Entries:     []fuseutil.Dirent{},
		EntriesList: map[string]*Node{},
	}
}

// InitializeChildNode creates new Node and adds it to parent Node#EntriesList.
func (n *Node) InitializeChildNode(name string, nextID fuseops.InodeID) *Node {
	defer debug(time.Now(), "Parent=%s Name=%s ID=%d", n.Name, name, nextID)

	c := NewNode(n.Transport, n.NodeIDGen)
	c.ID = nextID
	c.Name = name
	c.RemotePath = filepath.Join(n.RemotePath, name)
	c.LocalPath = filepath.Join(n.LocalPath, name)
	c.EntryType = fuseutil.DT_Directory
	c.Attrs = fuseops.InodeAttributes{Nlink: 1, Uid: n.Attrs.Uid, Gid: n.Attrs.Gid}

	n.EntriesList[c.Name] = c

	return c
}

// FindChild returns Node with specificed name. It calls `ReadDir` to refresh its
// cache first if cache is empty.
func (n *Node) FindChild(name string) (*Node, error) {
	if len(n.EntriesList) == 0 {
		_, err := n.getEntriesFromRemote()
		if err != nil {
			return nil, err
		}
	}

	if child, ok := n.EntriesList[name]; ok {
		return child, nil
	}

	return nil, ErrNodeNotFound
}

// ReadDir returns all files and directories that are inside this Node. It
// returns `fuse.EIO` if it's a directory. It returns from previously fetched
// entries from cache if they exists, otherwise fetches from user VM, saving
// to its cache once fetched.
func (n *Node) ReadDir() ([]fuseutil.Dirent, error) {
	defer debug(time.Now(), "Name=%s", n.Name)

	if n.EntryType != fuseutil.DT_Directory {
		return nil, fuse.EIO
	}

	if len(n.Entries) != 0 {
		return n.Entries, nil
	}

	return n.getEntriesFromRemote()
}

func (n *Node) Mkdir(name string, mode os.FileMode) (*Node, error) {
	defer debug(time.Now(), "Name=%s Mode=%s", name, mode)

	treq := struct {
		Path      string
		Recursive bool
	}{
		Path:      filepath.Join(n.RemotePath, name),
		Recursive: true,
	}
	var tres bool
	if err := n.Trip("fs.createDirectory", treq, &tres); err != nil {
		return nil, err
	}

	nextID := n.NodeIDGen.Next()

	newFolderNode := n.InitializeChildNode(name, nextID)
	newFolderNode.Attrs.Mode = mode

	_, err := n.getEntriesFromRemote()
	return newFolderNode, err
}

func (n *Node) getEntriesFromRemote() ([]fuseutil.Dirent, error) {
	req := struct{ Path string }{n.RemotePath}
	res := transport.FsReadDirectoryRes{}
	if err := n.Trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	var dirents []fuseutil.Dirent
	for index, file := range res.Files {
		var fileType fuseutil.DirentType = fuseutil.DT_File
		if file.IsDir {
			fileType = fuseutil.DT_Directory
		}

		nextID := n.NodeIDGen.Next()
		ent := fuseutil.Dirent{
			Offset: fuseops.DirOffset(index) + 1, // offset is 1 indexed
			Inode:  nextID,
			Name:   file.Name,
			Type:   fileType,
		}

		dirents = append(dirents, ent)

		child := n.InitializeChildNode(file.Name, nextID)
		child.Attrs.Mode = file.Mode
		child.EntryType = fileType

		n.EntriesList[file.Name] = child
	}

	n.Entries = dirents

	return dirents, nil
}
