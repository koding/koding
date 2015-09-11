package fs

import (
	"sync"

	"github.com/jacobsa/fuse/fuseops"
)

// NodeIDGen is responsible for generating ids for newly created nodes. It is
// threadsafe and guaranteed to return unique ids.
type NodeIDGen struct {
	// Mutex protects the fields below.
	sync.Mutex

	// LastID is the last node id that was allocated to a Node.
	LastID fuseops.InodeID
}

// NewNodeIDGen is the required initializer for NodeIDGen. It sets LastID to
// fuseops.RootInodeID, ie 1 since that's the default ID for root.
func NewNodeIDGen() *NodeIDGen {
	return &NodeIDGen{Mutex: sync.Mutex{}, LastID: fuseops.RootInodeID}
}

// Next returns next available fuseops.InodeID.
func (i *NodeIDGen) Next() fuseops.InodeID {
	i.Lock()
	defer i.Unlock()

	i.LastID++
	return i.LastID
}
