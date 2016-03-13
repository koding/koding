package fuseklient

import (
	"fmt"

	"github.com/jacobsa/fuse/fuseutil"
)

// File represents a file system file and implements Node interface.
type File struct {
	// Entry is generic structure that contains commonality between File and Dir.
	*Entry

	////// Entry#RWLock protects the fields below.

	// IsDirty indicates if File has been written to, but not yet been synced
	// with remote.
	IsDirty bool

	// IsReset indicates if File was reset. This is used to update file contents
	// before writing to it. Without this, if file was reset, then written to
	// without reading it, it'll overwrite the file on remote.
	IsReset bool

	// content deals with byte contents of the file.
	content *ContentReadWriter

	Content []byte
}

// NewFile is the required initializer for File.
func NewFile(n *Entry) *File {
	return &File{
		Entry:   n,
		content: NewContentReadWriter(n.Transport, n.Path, int64(n.Attrs.Size)),
		Content: nil,
		IsDirty: false,
		IsReset: false,
	}
}

// ReadAt returns contents of file at specified offset. It returns io.EOF if
// ofset is greater than its Attrs#Size.
func (f *File) ReadAt(p []byte, offset int64) (int, error) {
	f.Lock()
	defer f.Unlock()

	return f.content.ReadAt(p, offset)
}

// Create creates a new file on remote with in memory content.
func (f *File) Create() error {
	f.Lock()
	defer f.Unlock()

	return f.content.Create()
}

// WriteAt saves specified content at specified offset. Note, this saves to
// internal cache only, user will need to call Sync to save to remote.
//
// If file was reset, it fetches contents from remote and then writes to it.
func (f *File) WriteAt(content []byte, offset int64) error {
	f.Lock()
	defer f.Unlock()

	if err := f.content.WriteAt(content, offset); err != nil {
		return err
	}

	f.Attrs.Size = uint64(f.content.Size)

	return nil
}

// TruncateTo reduces file contents to specified length.
func (f *File) TruncateTo(size uint64) error {
	f.Lock()
	defer f.Unlock()

	f.Attrs.Size = size

	return f.content.TruncateTo(size)
}

// Flush saves internal cache to remote.
func (f *File) Flush() error {
	f.Lock()
	defer f.Unlock()

	return f.content.Save()
}

// Sync saves internal cache to remote.
func (f *File) Sync() error {
	return f.Flush()
}

///// Node interface

// GetType returns fuseutil.DT_File for identification for fuse library.
func (f *File) GetType() fuseutil.DirentType {
	return fuseutil.DT_File
}

// Expire fetches content from from remote and changes its InodeID to next
// available one. This is required to deal with cases where remote has updated
// but Kernel has cached the file attrs.
func (f *File) Expire() error {
	f.Lock()
	defer f.Unlock()

	// OH THE HORROR!
	// If remote has a change where size of file hasn't changed, then Kernel
	// doesn't invalidate the local cache, so we replace the InodeId.
	f.ID = f.Parent.IDGen.Next()

	return f.content.ReadAll()
}

func (f *File) ToString() string {
	f.RLock()
	defer f.RUnlock()

	eToS := f.Entry.ToString()
	return fmt.Sprintf(
		"%s\nfile: size=%d memSize=%d isDirty=%v",
		eToS, f.Attrs.Size, len(f.Content), f.IsDirty,
	)
}

// Reset delete local contents and sets IsReset flag.
func (f *File) Reset() error {
	f.Lock()
	defer f.Unlock()

	f.content.Reset()

	return nil
}

func (f *File) ResetAndRead() error {
	f.Lock()
	defer f.Unlock()

	return f.content.ResetAndRead()
}
