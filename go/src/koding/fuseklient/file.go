package fuseklient

import (
	"fmt"
	"io"

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

	// Content is the remotely fetched contents of the File.
	Content []byte
}

// NewFile is the required initializer for File.
func NewFile(n *Entry) *File {
	return &File{
		Entry:   n,
		Content: []byte{},
		IsDirty: false,
		IsReset: false,
	}
}

// ReadAt returns contents of file at specified offset. It returns io.EOF if
// ofset is greater than its Attrs#Size.
func (f *File) ReadAt(offset int64) ([]byte, error) {
	f.Lock()
	defer f.Unlock()

	if offset >= int64(f.Attrs.Size) {
		return nil, io.EOF
	}

	// fetch from remote when local size doesn't match remote
	if len(f.Content) != int(f.Attrs.Size) {
		if err := f.updateContentFromRemote(); err != nil {
			return nil, err
		}
	}

	return f.Content[offset:], nil
}

// Create creates a new file on remote with existing content.
func (f *File) Create() error {
	f.Lock()
	defer f.Unlock()

	return f.writeContentToRemote(f.Content)
}

// WriteAt saves specified content at specified offset. Note, this saves to
// internal cache only, user will need to call Sync to save to remote.
//
// If file was reset, it fetches contents from remote and then writes to it.
func (f *File) WriteAt(content []byte, offset int64) error {
	f.Lock()
	defer f.Unlock()

	if f.IsReset {
		if err := f.updateContentFromRemote(); err != nil {
			return err
		}
	}

	f.IsDirty = true

	var newLen = len(content) + int(offset)
	if len(f.Content) < newLen {
		padding := make([]byte, newLen-len(f.Content))
		f.Content = append(f.Content, padding...)
	}

	copy(f.Content[offset:], content)

	if offset == 0 {
		f.Content = f.Content[0:len(content)]
	}

	f.Attrs.Size = uint64(len(f.Content))

	return nil
}

// TruncateTo reduces file contents to specified length.
func (f *File) TruncateTo(size uint64) error {
	f.Lock()
	defer f.Unlock()

	s := int(size)
	switch {
	case s < len(f.Content):
		// specified size less than size of file, so remove all content over size
		f.Content = f.Content[:size]
	case s > len(f.Content):
		// specified size greater same as size of file, so add empty padding to
		// existing content
		f.Content = append(f.Content, make([]byte, s-len(f.Content))...)
	case s == len(f.Content):
		// specified size is same as size of file, so nothing to be done
	}

	return f.writeContentToRemote(f.Content)
}

// Flush saves internal cache to remote.
func (f *File) Flush() error {
	f.Lock()
	defer f.Unlock()

	return f.syncToRemote()
}

// Sync saves internal cache to remote.
func (f *File) Sync() error {
	f.Lock()
	defer f.Unlock()

	return f.syncToRemote()
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

	return f.updateContentFromRemote()
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

	f.Content = nil
	f.IsReset = true

	return nil
}

///// Helpers

func (f *File) syncToRemote() error {
	// return if:
	//   file is not dirty, ie not written since last remote sync
	//   file was reset, ie local cache was purged
	if !f.IsDirty || f.IsReset {
		return nil
	}

	return f.writeContentToRemote(f.Content)
}

func (f *File) writeContentToRemote(content []byte) error {
	f.resetFlags()
	return f.Transport.WriteFile(f.Path, content)
}

func (f *File) updateContentFromRemote() error {
	res, err := f.Transport.ReadFile(f.Path)
	if err != nil {
		return err
	}

	n := make([]byte, len(res.Content))
	copy(n, res.Content)

	f.Content = n
	f.Attrs.Size = uint64(len(f.Content))

	f.resetFlags()

	return nil
}

func (f *File) resetFlags() {
	f.IsDirty = false
	f.IsReset = false
}
