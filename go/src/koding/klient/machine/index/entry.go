package index

import (
	"os"
	"sync/atomic"
	"time"

	"github.com/djherbis/times"
)

// EntryPromise describes the promised state of index entry.
type EntryPromise uint32

const (
	EntryPromiseSync   EntryPromise = 1 << iota // S: sync promise, doesn't exist locally.
	EntryPromiseAdd                             // A: sync promise after adding, exists locally.
	EntryPromiseUpdate                          // U: sync promise after updating, exists locally.
	EntryPromiseDel                             // D: sync promise after deleting, doesn't exist locally.
	EntryPromiseUnlink                          // N: sync promise after hard delete, doesn't exist locally.
)

var epMapping = map[byte]EntryPromise{
	'S': EntryPromiseSync,
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

// IncRefCounter increments entry reference counter.
func (e *Entry) IncRefCounter() int32 {
	return atomic.AddInt32(&e.virtual.refCount, 1)
}

// DecRefCounter decrements entry reference counter.
func (e *Entry) DecRefCounter() int32 {
	return atomic.AddInt32(&e.virtual.refCount, -1)
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

// ctime gets file's change time in UNIX Nano format.
func ctime(fi os.FileInfo) int64 {
	if tspec := times.Get(fi); tspec.HasChangeTime() {
		return tspec.ChangeTime().UnixNano()
	}

	return 0
}
