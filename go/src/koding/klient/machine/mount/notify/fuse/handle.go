package fuse

import (
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"syscall"

	"koding/klient/machine/index/node"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
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

	size  int64
	write bool
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

// GrowSize gets the highest of stored size and provided one and stores it to
// handle. Return value will contain the chosen one and should be set as new
// inode size value.
func (fh *FileHandle) GrowSize(new int64) int64 {
	if new > fh.size {
		fh.size = new
	}

	return fh.size
}

// Write sets write flag to true. This function should be called on all write
// operations performed on file descriptor.
func (fh *FileHandle) Write() { fh.write = true }

// IsModified returns true when the content pointed by file descriptor was
// modified by write operations.
func (fh *FileHandle) IsModified() bool {
	return fh.write
}

// FileHandleGroup stores currently opened files.
type FileHandleGroup struct {
	generator func() uint64

	mu      sync.Mutex
	handles map[fuseops.HandleID]*FileHandle
}

// NewFileHandleGroup creates a new FileHandleGroup object.
func NewFileHandleGroup(gen func() uint64) *FileHandleGroup {
	if gen == nil {
		panic("generator must be non-nil")
	}

	return &FileHandleGroup{
		generator: gen,
		handles:   make(map[fuseops.HandleID]*FileHandle),
	}
}

// Add creates a file handle for already opened file. The provided file should
// be closed by calling file handle group release method.
func (fhg *FileHandleGroup) Add(inodeID fuseops.InodeID, f *os.File, size int64) fuseops.HandleID {
	handleID := fuseops.HandleID(fhg.generator())

	fh := &FileHandle{
		InodeID: inodeID,
		File:    f,
		size:    size,
	}

	fhg.mu.Lock()
	if _, ok := fhg.handles[handleID]; ok {
		panic("duplicated handle identifier")
	}
	fhg.handles[handleID] = fh
	fhg.mu.Unlock()

	return handleID
}

// Open opens a file pointed by a given node. The node must exist.
func (fhg *FileHandleGroup) Open(root string, n *node.Node) (fuseops.HandleID, error) {
	if !n.Exist() {
		return 0, fuse.ENOENT
	}

	absPath := filepath.Join(root, n.Path())
	f, err := os.OpenFile(absPath, os.O_RDWR, n.Entry.File.Mode)
	if os.IsNotExist(err) {
		return 0, fuse.ENOENT
	} else if os.IsPermission(err) {
		f, err = os.OpenFile(absPath, os.O_RDONLY, n.Entry.File.Mode)
	}

	if err != nil {
		return 0, toErrno(err)
	}

	return fhg.Add(fuseops.InodeID(n.Entry.File.Inode), f, n.Entry.File.Size), nil
}

// Get gets the FileHandle structure associated with provided handle ID.
func (fhg *FileHandleGroup) Get(handleID fuseops.HandleID) (fh *FileHandle, err error) {
	fhg.mu.Lock()
	fh, ok := fhg.handles[handleID]
	fhg.mu.Unlock()

	if !ok {
		return fh, fuse.EINVAL
	}

	return fh, nil
}

// Release releases file handle. The underlying file descriptor will be closed.
func (fhg *FileHandleGroup) Release(handleID fuseops.HandleID) error {
	fhg.mu.Lock()
	fh, ok := fhg.handles[handleID]
	if !ok {
		fhg.mu.Unlock()
		return fuse.EINVAL
	}
	delete(fhg.handles, handleID)
	fhg.mu.Unlock()

	// Return error but drop the handle anyway.
	return fh.Close()
}

// Close closes all remaining file handles and cleans its internal state. This
// function doesn't reset object's HandleID generator.
func (fhg *FileHandleGroup) Close() error {
	fhg.mu.Lock()
	defer fhg.mu.Unlock()

	var err error
	for _, fh := range fhg.handles {
		if fh == nil {
			continue
		}

		if e := fh.Close(); e != nil && err == nil {
			err = e
		}
	}

	return err
}

// DirHandle describes the underlying filesystem's opened directory.
type DirHandle struct {
	InodeID fuseops.InodeID

	mu     sync.Mutex
	stream []fuseutil.Dirent

	offset fuseops.DirOffset

	// Index node of mount parrent.
	mDirParentInode fuseops.InodeID
}

// NewDirHandle creates a new DirHandle instance.
func NewDirHandle(mDirParentInode fuseops.InodeID, n *node.Node) *DirHandle {
	dh := &DirHandle{
		InodeID:         fuseops.InodeID(n.Entry.File.Inode),
		mDirParentInode: mDirParentInode,
	}
	dh.stream = dh.readDirents(n)

	return dh
}

// Offset returns current directory stream offset.
func (dh *DirHandle) Offset() (offset fuseops.DirOffset) {
	dh.mu.Lock()
	offset = dh.offset
	dh.mu.Unlock()

	return
}

// ReadDir writes dirents do provided destination slice. It returns the number
// of read bytes.
func (dh *DirHandle) ReadDir(offset fuseops.DirOffset, dst []byte) (n int, err error) {
	dh.mu.Lock()
	if int(offset) > len(dh.stream) {
		dh.mu.Unlock()
		return 0, fuse.EINVAL
	}

	var chunkN int
	for _, dirent := range dh.stream[int(offset):] {
		if dirent.Name == "" {
			continue
		}

		if chunkN = fuseutil.WriteDirent(dst[n:], dirent); chunkN == 0 {
			break
		}

		dh.offset = dirent.Offset
		n += chunkN
	}

	dh.mu.Unlock()

	return n, nil
}

// Rewind behaves like rewinddir(), it resets directory steram.
func (dh *DirHandle) Rewind(offset fuseops.DirOffset, n *node.Node) {
	// Sanity check. There is a logic error when we rewinding different inodes.
	if dh.InodeID != fuseops.InodeID(n.Entry.File.Inode) {
		panic("called rewind on invalid node")
	}

	dh.mu.Lock()
	dh.stream = dh.readDirents(n)
	dh.offset = offset
	dh.mu.Unlock()
}

// readDirents reads node child names and converts them to dirents adding
// dot and dot-dot dirents.
func (dh *DirHandle) readDirents(n *node.Node) (ds []fuseutil.Dirent) {
	ds = make([]fuseutil.Dirent, 0, n.ChildN()+2)

	n.Children(0, func(child *node.Node) {
		if !child.Exist() {
			return
		}

		ds = append(ds, fuseutil.Dirent{
			Offset: fuseops.DirOffset(len(ds)) + 1,
			Inode:  fuseops.InodeID(child.Entry.File.Inode),
			Name:   child.Name,
			Type:   direntType(child.Entry),
		})
	})

	// Add "." directory.
	ds = append(ds, fuseutil.Dirent{
		Offset: fuseops.DirOffset(len(ds)) + 1,
		Inode:  fuseops.InodeID(n.Entry.File.Inode),
		Name:   ".",
		Type:   fuseutil.DT_Directory,
	})

	// Add ".." directory.
	inode := dh.mDirParentInode
	if parent := n.Parent(); parent != nil {
		inode = fuseops.InodeID(parent.Entry.File.Inode)
	} else if inode == 0 {
		return ds
	}

	ds = append(ds, fuseutil.Dirent{
		Offset: fuseops.DirOffset(len(ds)) + 1,
		Inode:  inode,
		Name:   "..",
		Type:   fuseutil.DT_Directory,
	})

	return ds
}

// direntType gets dirent type from a given node.
func direntType(entry *node.Entry) fuseutil.DirentType {
	if entry.File.Mode.IsDir() {
		return fuseutil.DT_Directory
	}
	return fuseutil.DT_File
}

// DirHandleGroup stores currently opened directories.
type DirHandleGroup struct {
	generator func() uint64

	mu      sync.Mutex
	handles map[fuseops.HandleID]*DirHandle

	// Index node of mount parrent.
	mDirParentInode fuseops.InodeID
}

// NewDirHandleGroup creates a new DirHandleGroup object.
func NewDirHandleGroup(mountDir string, gen func() uint64) *DirHandleGroup {
	if gen == nil {
		panic("generator must be non-nil")
	}

	return &DirHandleGroup{
		generator:       gen,
		handles:         make(map[fuseops.HandleID]*DirHandle),
		mDirParentInode: getMountPointParentInode(mountDir),
	}
}

// Open opens or creates a file under provided path and returns its handle.
func (dhg *DirHandleGroup) Open(n *node.Node) fuseops.HandleID {
	handleID := fuseops.HandleID(dhg.generator())

	dhg.mu.Lock()
	if _, ok := dhg.handles[handleID]; ok {
		panic("duplicated handle identifier")
	}
	dhg.handles[handleID] = NewDirHandle(dhg.mDirParentInode, n)
	dhg.mu.Unlock()

	return handleID
}

// Get gets the DirHandle structure associated with provided handle ID.
func (dhg *DirHandleGroup) Get(handleID fuseops.HandleID) (dh *DirHandle, err error) {
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
