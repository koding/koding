package fs

import (
	"sync"

	"github.com/jacobsa/fuse/fuseops"
)

// Node is the generic term of File and Dir in FileSystem.
type Node struct {
	// RWLock protects the fields below.
	sync.RWMutex

	// Attrs is the list of attributes.
	Attrs fuseops.InodeAttributes
}
