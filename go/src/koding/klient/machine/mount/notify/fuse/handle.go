package fuse

import (
	"os"
	"sync"
	"sync/atomic"
	"syscall"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
)

// MinHandleID defines the minimum value of file handle.
const MinHandleID = 3

// generator creates a unique number generator. It's safe to call it
// concurrently. The generated numbers will always be greater than min value.
func generator(min uint64) func() uint64 {
	var current = min
	return func() (res uint64) {
		for {
			if res = atomic.AddUint64(&current, 1); res > min {
				return
			}
		}
	}
}

// FileHandle contains file handle index node ID and the underlying filesystem's
// file.
type FileHandle struct {
	InodeID fuseops.InodeID
	File    *os.File
}

// Close closes stored file handle.
func (fh *FileHandle) Close() error {
	if fh == nil || fh.File == nil {
		return syscall.EINVAL
	}

	if err := fh.File.Close(); err != nil {
		return toErrno(err)
	}

	return nil
}

// FileHandleGroup stores currently opened files.
type FileHandleGroup struct {
	generator func() uint64

	mu      sync.Mutex
	handles map[fuseops.HandleID]FileHandle
}

// NewFileHandleGroup creates a new FileHandleGroup object.
func NewFileHandleGroup(gen func() uint64) *FileHandleGroup {
	if gen == nil {
		panic("generator must be non-nil")
	}

	return &FileHandleGroup{
		generator: gen,
		handles:   make(map[fuseops.HandleID]FileHandle),
	}
}

// Open opens or creates a file under provided path and returns its handle.
func (fhg *FileHandleGroup) Open(inodeID fuseops.InodeID, path string, mode os.FileMode) fuseops.HandleID {
	return 0
}

// Close closes all remaining file handles and cleans its internal state. This
// function doesn't reset object's HandleID generator.
func (fhg *FileHandleGroup) Close() error {
	fhg.mu.Lock()
	defer fhg.mu.Unlock()

	var err error
	for _, fh := range fhg.handles {
		if e := fh.Close(); e != nil && err == nil {
			err = e
		}
	}

	return err
}

// DirHandle describes the underlying filesystem's opened directory.
type DirHandle struct {
	InodeID fuseops.InodeID
}

// DirHandleGroup stores currently opened directories.
type DirHandleGroup struct {
	generator func() uint64

	mu      sync.Mutex
	handles map[fuseops.HandleID]DirHandle
}

// NewDirHandleGroup creates a new DirHandleGroup object.
func NewDirHandleGroup(gen func() uint64) *DirHandleGroup {
	if gen == nil {
		panic("generator must be non-nil")
	}

	return &DirHandleGroup{
		generator: gen,
		handles:   make(map[fuseops.HandleID]DirHandle),
	}
}

// Open opens or creates a file under provided path and returns its handle.
func (dhg *DirHandleGroup) Open(inodeID fuseops.InodeID) fuseops.HandleID {
	handleID := fuseops.HandleID(dhg.generator())

	dhg.mu.Lock()
	if _, ok := dhg.handles[handleID]; ok {
		panic("duplicated handle identifier")
	}
	dhg.handles[handleID] = DirHandle{InodeID: inodeID}
	dhg.mu.Unlock()

	return handleID
}

// Get gets the DirHandle structure associated with provided handle ID.
func (dhg *DirHandleGroup) Get(handleID fuseops.HandleID) (dh DirHandle, err error) {
	dhg.mu.Lock()
	dh, ok := dhg.handles[handleID]
	dhg.mu.Unlock()

	if !ok {
		return dh, fuse.EINVAL
	}

	return dh, nil
}

// Release releases directory handle.
func (dhg *DirHandleGroup) Release(handleID fuseops.HandleID) error {
	dhg.mu.Lock()
	if _, ok := dhg.handles[handleID]; !ok {
		dhg.mu.Unlock()
		return fuse.EINVAL
	}
	delete(dhg.handles, handleID)
	dhg.mu.Unlock()

	return nil
}
