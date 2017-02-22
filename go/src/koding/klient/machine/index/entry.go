package index

import (
	"encoding/json"
	"os"
	"sync/atomic"
	"time"

	"fmt"

	"github.com/djherbis/times"
)

// EntryPromise describes the promised state of index entry.
type EntryPromise uint32

const (
	EntryPromiseVirtual EntryPromise = 1 << iota // E: promise that file exists, doesn't exist locally.
	EntryPromiseAdd                              // A: promise after adding, exists locally.
	EntryPromiseUpdate                           // U: promise after updating, exists locally.
	EntryPromiseDel                              // D: promise after deleting, doesn't exist locally.
	EntryPromiseUnlink                           // N: promise after hard delete, doesn't exist locally.
)

var epMapping = map[byte]EntryPromise{
	'V': EntryPromiseVirtual,
	'A': EntryPromiseAdd,
	'U': EntryPromiseUpdate,
	'D': EntryPromiseDel,
	'N': EntryPromiseUnlink,
}

// String implements fmt.Stringer interface and pretty prints stored promise.
func (ep EntryPromise) String() string {
	var buf [8]byte // Promise is uint32 but we don't need more than 8.
	for c, i := range epMapping {
		w := getPowerOf2(uint64(i))
		if ep&i != 0 {
			buf[w] = c
		} else {
			buf[w] = '-'
		}
	}

	return string(buf[:len(epMapping)])
}

// realEntry describes the part of entry which is independent of underlying file
// system. The fields of this type can be stored on disk and transferred over
// network.
type realEntry struct {
	CTime int64       `json:"c"` // Metadata change time since EPOCH.
	MTime int64       `json:"m"` // File data change time since EPOCH.
	Size  int64       `json:"s"` // Size of the file.
	Mode  os.FileMode `json:"o"` // File mode and permission bits.
}

// virtualEntry stores virtual file system dependent data that is lost during
// serialization and should be recreated by VFS which manages the entries.
type virtualEntry struct {
	inode    uint64       // Inode ID of a mounted file.
	refCount int32        // Reference count of file handlers.
	promise  EntryPromise // Metadata of files's memory state.
}

var (
	_ json.Marshaler   = (*Index)(nil)
	_ json.Unmarshaler = (*Index)(nil)
)

// Entry represents a single file registered to index.
type Entry struct {
	real    realEntry
	virtual virtualEntry
}

// NewEntry creates a new entry that describes the wile with specified size and
// mode. VFS are zero values and must be set manually.
func NewEntry(size int64, mode os.FileMode) *Entry {
	t := time.Now().UTC().UnixNano()
	return NewEntryTime(t, t, size, mode)
}

// NewEntryFileInfo creates a new entry from a given file info.
func NewEntryFileInfo(info os.FileInfo) *Entry {
	return NewEntryTime(
		ctime(info),
		info.ModTime().UTC().UnixNano(),
		info.Size(),
		info.Mode(),
	)
}

// NewEntryTime creates a new entry with custom file change and modify times.
func NewEntryTime(ctime, mtime, size int64, mode os.FileMode) *Entry {
	return &Entry{
		real: realEntry{
			CTime: ctime,
			MTime: mtime,
			Size:  size,
			Mode:  mode,
		},
	}
}

// NewEntryFile creates a new entry which describes the given file.
func NewEntryFile(path string) (*Entry, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return nil, err
	}

	return NewEntryFileInfo(info), nil
}

// Copy returns a deep copy of the e value.
//
// RefCount field is ignored and set to 0.
func (e *Entry) Copy() *Entry {
	return &Entry{
		real: realEntry{
			CTime: e.CTime(),
			MTime: e.MTime(),
			Size:  e.Size(),
			Mode:  e.Mode(),
		},
		virtual: virtualEntry{
			inode:    e.Inode(),
			refCount: 0,
			promise:  e.Promise(),
		},
	}
}

// MergeIn overwrites e's fields with f's ones, but only
// with those values the are non-zero.
//
// RefCount and Promise fields are ignored.
func (e *Entry) MergeIn(f *Entry) {
	if t := f.CTime(); t != 0 {
		e.SetCTime(t)
	}
	if t := f.MTime(); t != 0 {
		e.SetMTime(t)
	}
	if n := f.Size(); n != 0 {
		e.SetSize(n)
	}
	if m := f.Mode(); m != 0 {
		e.SetMode(m)
	}
	if n := f.Inode(); n != 0 {
		e.SetInode(n)
	}
}

// CTime atomically gets entry change time in UNIX nano format.
func (e *Entry) CTime() int64 {
	return atomic.LoadInt64(&e.real.CTime)
}

// SetCTime atomically sets entry's change time. Time must be in UNIX nano format.
func (e *Entry) SetCTime(nano int64) {
	atomic.StoreInt64(&e.real.CTime, nano)
}

// MTime atomically gets entry modification time in UNIX nano format.
func (e *Entry) MTime() int64 {
	return atomic.LoadInt64(&e.real.MTime)
}

// SetMTime atomically sets entry's modification time. Time must be in UNIX nano
// format.
func (e *Entry) SetMTime(nano int64) {
	atomic.StoreInt64(&e.real.MTime, nano)
}

// Size atomically gets entry size in bytes.
func (e *Entry) Size() int64 {
	return atomic.LoadInt64(&e.real.Size)
}

// SetSize atomically sets entry's size. The size is provided in bytes.
func (e *Entry) SetSize(size int64) {
	atomic.StoreInt64(&e.real.Size, size)
}

// Mode atomically gets entry file mode.
func (e *Entry) Mode() os.FileMode {
	return os.FileMode(atomic.LoadUint32((*uint32)(&e.real.Mode)))
}

// SetMode atomically sets entry file mode.
func (e *Entry) SetMode(mode os.FileMode) {
	atomic.StoreUint32((*uint32)(&e.real.Mode), (uint32)(mode))
}

// Inode gets virtual file system inode.
func (e *Entry) Inode() uint64 {
	return atomic.LoadUint64(&e.virtual.inode)
}

// SetInode sets virtual file system inode.
func (e *Entry) SetInode(inode uint64) {
	atomic.StoreUint64(&e.virtual.inode, inode)
}

// RefCount returns the current state of Entry's reference counter.
func (e *Entry) RefCount() int32 {
	return atomic.LoadInt32(&e.virtual.refCount)
}

// IncRefCount increments entry reference counter.
func (e *Entry) IncRefCount() int32 {
	return atomic.AddInt32(&e.virtual.refCount, 1)
}

// DecRefCount decrements entry reference counter.
func (e *Entry) DecRefCount() int32 {
	return atomic.AddInt32(&e.virtual.refCount, -1)
}

// Promise returns Entry's promise state.
func (e *Entry) Promise() EntryPromise {
	return EntryPromise(atomic.LoadUint32((*uint32)(&e.virtual.promise)))
}

// HasPromise checks if provider promise is set in given entry.
func (e *Entry) HasPromise(promise EntryPromise) bool {
	return EntryPromise(atomic.LoadUint32((*uint32)(&e.virtual.promise)))&promise == promise
}

// Deleted checks if the entry is promised to be deleted.
func (e *Entry) Deleted() bool {
	return e.HasPromise(EntryPromiseDel) || e.HasPromise(EntryPromiseUnlink)
}

// SwapPromise flips the value of a promise field, setting the set bits and
// unsetting the unset ones. This function is thread safe.
func (e *Entry) SwapPromise(set, unset EntryPromise) EntryPromise {
	for {
		older := atomic.LoadUint32((*uint32)(&e.virtual.promise))
		updated := (older | uint32(set)) &^ uint32(unset)

		if atomic.CompareAndSwapUint32((*uint32)(&e.virtual.promise), older, updated) {
			return EntryPromise(updated)
		}
	}
}

// String implements fmt.Stringer interface. It pretty prints entry.
func (e *Entry) String() string {
	var (
		ctime = time.Unix(0, e.CTime())
		mtime = time.Unix(0, e.MTime())
	)

	return fmt.Sprintf("[INODE %d, REFS %d, PROMISE %s][CTIME %s, MTIME %s, SIZE %d, MODE %s]",
		e.Inode(), e.RefCount(), e.Promise(),
		ctime.Format(time.StampMilli), mtime.Format(time.StampMilli), e.Size(), e.Mode(),
	)
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals entry
// real data to JSON format.
func (e *Entry) MarshalJSON() ([]byte, error) {
	real := realEntry{
		CTime: e.CTime(),
		MTime: e.MTime(),
		Size:  e.Size(),
		Mode:  e.Mode(),
	}

	return json.Marshal(real)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private entry fields.
func (e *Entry) UnmarshalJSON(data []byte) error {
	return json.Unmarshal(data, &e.real)
}

// ctime gets file's change time in UNIX Nano format.
func ctime(fi os.FileInfo) int64 {
	if tspec := times.Get(fi); tspec.HasChangeTime() {
		return tspec.ChangeTime().UnixNano()
	}

	return 0
}
