package fuseklient

import (
	"sync"

	"github.com/jacobsa/fuse/fuseops"
)

// IDGen is responsible for generating ids for newly created Entry. It is
// threadsafe and guaranteed to return unique ids.
type IDGen struct {
	// Mutex protects the fields below.
	sync.Mutex

	// LastID is the last id that was allocated.
	LastID fuseops.InodeID
}

// NewIDGen is the required initializer for IDGen. It sets LastID to
// fuseops.RootInodeID, ie 1 since that's the default ID for root.
func NewIDGen() *IDGen {
	return &IDGen{Mutex: sync.Mutex{}, LastID: fuseops.RootInodeID}
}

// Next returns next available fuseops.InodeID.
func (i *IDGen) Next() fuseops.InodeID {
	i.Lock()
	defer i.Unlock()

	i.LastID++
	return i.LastID
}
