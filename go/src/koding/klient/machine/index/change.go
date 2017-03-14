package index

import (
	"sync/atomic"
	"time"
)

// ChangeMeta indicates what change has been done on a given file.
type ChangeMeta uint64

const (
	ChangeMetaLocal  ChangeMeta = 1 << iota // L: local->remote synchronization.
	ChangeMetaRemote                        // R: remote->local synchronization.
	ChangeMetaAdd                           // a: File was added.
	ChangeMetaRemove                        // d: File was removed.
	ChangeMetaUpdate                        // u: File was updated.
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
// object. Return value is the Change meta which was replaced.
//
// The rules of coalescing are:
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
func (cm *ChangeMeta) Coalesce(newer ChangeMeta) ChangeMeta {
	for {
		older := ChangeMeta(atomic.LoadUint64((*uint64)(cm)))

		// First five changes of change meta creates an index for udarlMap which
		// stores OR result of two change meta events. We strip other flags here.
		evIdx := (older | newer) & cmAll

		// Remove all changes and locations from coalesced mask.
		withoutEvent := (newer | older) &^ cmAll

		partial := udarlMap[evIdx]
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

		updated := uint64(withoutEvent | partial)
		if atomic.CompareAndSwapUint64((*uint64)(cm), uint64(older), updated) {
			return older
		}
	}
}

var cmMapping = map[byte]ChangeMeta{
	'L': ChangeMetaLocal,
	'R': ChangeMetaRemote,
	'a': ChangeMetaAdd,
	'd': ChangeMetaRemove,
	'u': ChangeMetaUpdate,
}

// String implements fmt.Stringer interface and pretty prints stored change.
func (cm *ChangeMeta) String() string {
	cpy := atomic.LoadUint64((*uint64)(cm))

	var buf [8]byte // Meta is uint64 but we don't need more than 8.
	for c, i := range cmMapping {
		w := getPowerOf2(uint64(i))
		if cpy&uint64(i) != 0 {
			buf[w] = c
		} else {
			buf[w] = '-'
		}
	}

	return string(buf[:len(cmMapping)])
}

func getPowerOf2(i uint64) (count int) {
	for ; i > 1; count++ {
		i = i >> 1
	}

	return count
}

// Similar checks if provided meta changes can be considered similar. This means
// if the same synchronization logic can be applied to provided meta changes.
func Similar(a, b ChangeMeta) bool {
	// Default to local change direction when not set.
	if a&(ChangeMetaRemote|ChangeMetaLocal) == 0 {
		a |= ChangeMetaLocal
	}
	if b&(ChangeMetaRemote|ChangeMetaLocal) == 0 {
		b |= ChangeMetaLocal
	}

	return (a^b)&cmAll == 0
}

// Priority describes change priority.
type Priority uint64

const (
	PriorityLow    Priority = 1 << iota // --+: low change priority.
	PriorityMedium                      // -++: medium change priority.
	PriorityHigh                        // +++: high change priority.
)

// Coalesce coalesces two priorities. Always the higher priority is chosen.
func (p *Priority) Coalesce(newer Priority) Priority {
	for {
		older := Priority(atomic.LoadUint64((*uint64)(p)))

		if older > newer {
			return older
		}

		if atomic.CompareAndSwapUint64((*uint64)(p), uint64(older), uint64(newer)) {
			return older
		}
	}
}

// String implements fmt.Stringer interface and pretty prints stored priority.
func (p *Priority) String() string {
	switch cpy := Priority(atomic.LoadUint64((*uint64)(p))); {
	case cpy&PriorityHigh != 0:
		return "+++"
	case cpy&PriorityMedium != 0:
		return "-++"
	case cpy&PriorityLow != 0:
		return "--+"
	default:
		return "---"
	}
}

// Change describes single file change.
type Change struct {
	path      string     // The relative path of the file.
	createdAt int64      // Change creation time since EPOCH.
	priority  Priority   // Change priority.
	meta      ChangeMeta // The type of operation made on file entry.
}

// NewChange creates a new Change object.
func NewChange(path string, priority Priority, meta ChangeMeta) *Change {
	return &Change{
		path:      path,
		priority:  priority,
		meta:      meta,
		createdAt: time.Now().UTC().UnixNano(),
	}
}

// Path returns the relative slashed path to changed file.
func (c *Change) Path() string { return c.path }

// CreatedAtUnixNano returns creation time since EPOCH in UTC time zone.
func (c *Change) CreatedAtUnixNano() int64 {
	return atomic.LoadInt64(&c.createdAt)
}

// Meta returns meta data information about Change type and direction.
func (c *Change) Meta() ChangeMeta {
	return ChangeMeta(atomic.LoadUint64((*uint64)(&c.meta)))
}

// Priority returns change priority.
func (c *Change) Priority() Priority {
	return Priority(atomic.LoadUint64((*uint64)(&c.priority)))
}

// Coalesce merges two changes with the same path. If change paths are different
// this method panics. Meta data will be updated according to ChangeMeta
// coalescing rules. Higher creation time is always chosen. This method is
// thread safe. Return value is the Change which was replaced.
func (c *Change) Coalesce(newer *Change) *Change {
	if newer == nil {
		return &Change{}
	}

	if c.path != newer.path {
		panic("coalesce of different changes is prohibited")
	}

	// Data races between change meta and made time doesn't matter since the
	// time will end up being the lowest value.
	older := &Change{
		path:     c.path,
		meta:     c.meta.Coalesce(newer.Meta()),
		priority: c.priority.Coalesce(newer.Priority()),
	}

	for {
		older.createdAt = atomic.LoadInt64(&c.createdAt)

		newt := newer.CreatedAtUnixNano()
		if newt <= older.createdAt {
			return older
		}

		if atomic.CompareAndSwapInt64(&c.createdAt, older.createdAt, newt) {
			return older
		}
	}
}

// String implements fmt.Stringer interface. It pretty prints stored change.
func (c *Change) String() string {
	age := time.Now().UTC().Sub(time.Unix(0, c.CreatedAtUnixNano()))
	return c.meta.String() + " " + c.priority.String() + " " + age.String() + " " + c.path
}

// ChangeSlice stores multiple changes.
type ChangeSlice []*Change

func (cs ChangeSlice) Len() int           { return len(cs) }
func (cs ChangeSlice) Swap(i, j int)      { cs[i], cs[j] = cs[j], cs[i] }
func (cs ChangeSlice) Less(i, j int) bool { return cs[i].path < cs[j].path }
