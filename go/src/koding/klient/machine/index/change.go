package index

import (
	"sync/atomic"
	"time"
)

// ChangeMeta indicates what change has been done on a given file.
type ChangeMeta uint64

const (
	ChangeMetaLocal  ChangeMeta = 1 << iota // local->remote synchronization.
	ChangeMetaRemote                        // remote->local synchronization.
	ChangeMetaAdd                           // File was added.
	ChangeMetaRemove                        // File was removed.
	ChangeMetaUpdate                        // File was updated.
	ChangeMetaLarge                         // File size is above 4GB.
)

// Followed constants are helpers for ChangeMeta.Coalesce method.
const (
	cmInv = 0
	cmEv  = ChangeMetaUpdate | ChangeMetaRemove | ChangeMetaAdd
	cmAll = cmEv | ChangeMetaRemote | ChangeMetaLocal

	cmUL = ChangeMetaUpdate | ChangeMetaLocal
	cmDL = ChangeMetaRemove | ChangeMetaLocal
	cmAL = ChangeMetaAdd | ChangeMetaLocal

	cmUR = ChangeMetaUpdate | ChangeMetaRemote
	cmDR = ChangeMetaRemove | ChangeMetaRemote
	cmAR = ChangeMetaAdd | ChangeMetaRemote
)

// udarlMap is a helper array used to map coalesced changes to new change. It
// has all((3+2)^5) combinations of UDA events and RL directions.
var udarlMap = [32]ChangeMeta{
	cmInv, cmInv, cmInv, cmInv,
	cmAL, cmAL, cmAR, cmUL,
	cmDL, cmDL, cmDR, cmDL,
	cmUL, cmUL, cmUR, cmAll,
	cmUL, cmUL, cmUR, cmUL,
	cmAL, cmAL, cmAR, cmUL,
	cmDL, cmDL, cmDR, cmAll,
	cmInv, cmInv, cmInv, cmInv,
}

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
// Example: If add remote change(AR) is merged with update local (UL) change,
//          the coalesced event will be update local AR+UL=UL. This means that
//          local updated file should overwrite remotely added one.
//
// All other flags are OR-ed. The coalesce matrix must be kept triangular.
func (cm *ChangeMeta) Coalesce(newer ChangeMeta) {
	for {
		older := ChangeMeta(atomic.LoadUint64((*uint64)(cm)))

		partial := udarlMap[(older|newer)&31]

		// There are special cases where OR-ed order of events is different:
		//   DR+UL=AL or DL+UR=DL,
		//   DR+AL=AL or DL+AR=DL.
		// in such case we return cmAll and try to deduce who is holding which event.
		if partial == cmAll {
			if older&cmDR == cmDR || newer&cmDR == cmDR {
				partial = cmAL
			} else {
				partial = cmDL
			}
		}

		updated := uint64((newer|older)&^cmAll | partial)
		if atomic.CompareAndSwapUint64((*uint64)(cm), uint64(older), updated) {
			return
		}
	}
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
