package index

import (
	"sync/atomic"
	"time"
)

// ChangeMeta indicates what change has been done on a given file.
type ChangeMeta uint64

const (
	ChangeMetaUpdate ChangeMeta = 1 << iota // File was updated.
	ChangeMetaRemove                        // File was removed.
	ChangeMetaAdd                           // File was added.

	ChangeMetaLarge  ChangeMeta = 1 << (8 + iota) // File size is above 4GB.
	ChangeMetaRemote                              // remote->local synchronization.
	ChangeMetaLocal                               // local->remote synchronization.
)

// Coalesce coalesces two meta-data changes and saves the result to called
// object. The rules of coalescing are:
//
//  U - update; D - remove(delete); A - add; L - local; R - remote.
//
//      | UL | DL | AL | UR | DR | AR |
//      +----+----+----+----+----+----+----
//      | UL | DL | AL | UL | AL | UL | UL
//      +----+----+----+----+----+----+----
//           | DL | UL | DL | DL | DL | DL
//           +----+----+----+----+----+----
//                | AL | UL | AL | UL | AL
//                +----+----+----+----+----
//                     | UR | DR | AR | UR
//                     +----+----+----+----
//                          | DR | UR | DR
//                          +----+----+----
//                               | AR | AR
//                               +----+----
//
// All other flags are OR-ed. The coalesce matrix must be kept triangular.
func (cm *ChangeMeta) Coalesce(newer ChangeMeta) {
	atomic.StoreUint64((*uint64)(cm), uint64(newer))
}

// Change describes single file change.
type Change struct {
	name string     // The relative name of the file.
	made int64      // Change creation time since EPOCH.
	meta ChangeMeta // The type of operation made on file entry.
}

// NewChange creates a new Change object.
func NewChange(name string, meta ChangeMeta) *Change {
	return &Change{
		name: name,
		meta: meta,
		made: time.Now().UTC().UnixNano(),
	}
}

// Name returns the relative slashed path to changed file.
func (c *Change) Name() string { return c.name }

// MadeUnixNano returns creation time since EPOCH in UTC time zone.
func (c *Change) MadeUnixNano() int64 {
	return atomic.LoadInt64(&c.made)
}

// Meta returns meta data information about Change type and direction.
func (c *Change) Meta() ChangeMeta {
	return ChangeMeta(atomic.LoadUint64((*uint64)(&c.meta)))
}

// ChangeSlice stores multiple changes.
type ChangeSlice []*Change

func (cs ChangeSlice) Len() int           { return len(cs) }
func (cs ChangeSlice) Swap(i, j int)      { cs[i], cs[j] = cs[j], cs[i] }
func (cs ChangeSlice) Less(i, j int) bool { return cs[i].name < cs[j].name }
