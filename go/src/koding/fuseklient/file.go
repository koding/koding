package fuseklient

import (
	"fmt"
	"path/filepath"

	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
)

// File represents a file system file and implements Node interface.
type File struct {
	// Entry is generic structure that contains commonality between File and Dir.
	*Entry

	////// Entry#RWLock protects the fields below.

	// content deals with byte contents of the file.
	content *ContentReadWriter
}

// NewFile is the required initializer for File.
func NewFile(n *Entry) *File {
	return &File{
		Entry:   n,
		content: NewContentReadWriter(n.Transport, &n.Path, int64(n.Attrs.Size)),
	}
}

// ReadAt returns contents of file at specified offset. It returns io.EOF if
// ofset is greater than its Attrs#Size.
func (f *File) ReadAt(p []byte, offset int64) (int, error) {
	f.Lock()
	defer f.Unlock()

	return f.content.ReadAt(&p, offset)
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

	if err := f.content.TruncateTo(size); err != nil {
		return err
	}

	// set size after success remote truncate
	f.Attrs.Size = size

	return nil
}

// Flush saves internal cache to remote.
func (f *File) Flush() error {
	f.Lock()
	defer f.Unlock()

	return f.content.Save(false)
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

	// fetch the updated attrs
	attrs, err := f.getAttrsFromRemote()
	if err != nil {
		return err
	}

	f.setAttrs(attrs)

	return f.content.ReadAll()
}

func (f *File) GetRemotePath() string {
	return filepath.Join(f.Transport.GetRemotePath(), f.Path)
}

func (f *File) ToString() string {
	f.RLock()
	defer f.RUnlock()

	eToS := f.Entry.ToString()
	return fmt.Sprintf(
		"%s\nfile: size=%d memSize=%d isDirty=%v",
		eToS, f.Attrs.Size, len(f.content.content), f.content.isDirty,
	)
}

// Reset delete local contents and sets IsReset flag.
func (f *File) Reset() error {
	f.Lock()
	defer f.Unlock()

	f.content.Reset()

	return nil
}

func (f *File) SetAttrs(attrs *fuseops.InodeAttributes) {
	f.Lock()
	defer f.Unlock()

	f.setAttrs(attrs)
}

func (f *File) setAttrs(attrs *fuseops.InodeAttributes) {
	f.Attrs = attrs
	f.content.Size = int64(attrs.Size)
}

func (f *File) ResetAndRead() error {
	f.Lock()
	defer f.Unlock()

	return f.content.ResetAndRead()
}

func (f *File) GetContent() []byte {
	f.RLock()
	defer f.RUnlock()

	return f.content.content
}

func (f *File) SetContent(content []byte) {
	f.Lock()
	defer f.Unlock()

	n := make([]byte, len(content))
	copy(n, content)

	f.content.content = n
	f.content.Size = int64(len(content))
	f.Attrs.Size = uint64(len(content))
}
