package fuseklient

import (
	"errors"
	"io"
)

const (
	// DefaultBlockSize specifies how much data to ask from remote when reading a
	// file. This is a tradeoff between time waiting for data vs. amount of remote
	// calls.
	DefaultBlockSize = 4096 * 10
)

var (
	// ErrCreateOnNotEmpty is returned when ContentReadWriter#Create is called
	// file with size greater than 0. This is a precaution to prevent overwriting
	// files that have already been created on remote. Use ContentReadWriter#Save
	// instead.
	ErrCreateOnNotEmpty = errors.New(
		"File#Create called on file sized > 0. Use File#Save instead.",
	)
)

// remote is required interface to talk to remote machine.
type remote interface {
	ReadFileAt([]byte, string, int64, int64) (int, error)
	WriteFile(string, []byte) error
}

// ContentReadWriter represents remote file content related operations. It's
// upto the caller to lock appropriately to allow for thread safe access.
type ContentReadWriter struct {
	remote

	// Path is the full path on locally mounted folder. Note it does not contain.
	// the remote path prefix, that's in transport.
	Path *string

	// Size is the size of file on local. Note this can differ from remote if
	// file was written to, but not yet synced to remote.
	Size int64

	// BlockSize is the size of data to request from remote on each run.
	BlockSize int64

	// isDirty indicates if File has been written to, but not yet been synced
	// with remote.
	isDirty bool

	// content is byte slice of actual contents of file. Note this is lazily
	// populated. Use Size to determine actual size of content, not len(content).
	content []byte
}

// NewContentReadWriter is the required initializer for ContentReadWriter.
func NewContentReadWriter(t remote, path *string, size int64) *ContentReadWriter {
	return &ContentReadWriter{
		remote:    t,
		Path:      path,
		Size:      size,
		BlockSize: DefaultBlockSize,
		isDirty:   false,
		content:   nil,
	}
}

// Create saves file on remote. It returns an error if file size is > 0.
func (c *ContentReadWriter) Create() error {
	if c.Size > 0 {
		return ErrCreateOnNotEmpty
	}

	return c.writeContentToRemote(c.content)
}

// ReadAt reads contents of file from offset. Note it uses
// ContentReadWriter#BlockSize to specify how much to read rather than len(p).
// If content has been already fetched, it returns from memory, instead of
// fetching from remote. It returns the number of bytes read and and error, if
// any.
func (c *ContentReadWriter) ReadAt(p []byte, offset int64) (int, error) {
	if offset >= c.Size {
		return 0, io.EOF
	}

	// everything is fetched from remote already, so return from it
	if int64(len(c.content)) == c.Size {
		copied := copy(p, c.content[offset:])
		return copied, nil
	}

	return c.remote.ReadFileAt(p, *c.Path, offset, c.BlockSize)
}

// ResetAndRead is a helper method that zeroses out ContentReadWriter#content
// and reads it again from remote.
func (c *ContentReadWriter) ResetAndRead() error {
	c.Reset()
	return c.ReadAll()
}

// ReadAll fetches and saves content from remote by making x calls to
// ContentReadWriter#ReadAt. If len of content in memory is same as
// ContentReadWriter#Size, then it does nothing.
func (c *ContentReadWriter) ReadAll() error {
	// everything is fetched from remote already, so return
	if int64(len(c.content)) == c.Size {
		return nil
	}

	// only allocate what is required
	size := c.BlockSize
	if c.Size < size {
		size = c.Size
	}

	dst := make([]byte, size)
	var offset int64 = 0
	for offset < c.Size {
		cpd, err := c.remote.ReadFileAt(dst, *c.Path, offset, c.BlockSize)
		if err != nil && err != io.EOF { // ignore EOF errors
			return err
		}

		n := c.writeAt(dst[:cpd], offset)
		offset += int64(n)
	}

	return nil
}

// WriteAt writes specified byte slice to memory at specified offset to locally
// saved content. If necessary, it fetches all content from remote first. This
// done to prevent unsynced file from overwriting itself.
func (c *ContentReadWriter) WriteAt(content []byte, offset int64) error {
	if c.needSync() {
		if err := c.ReadAll(); err != nil {
			return err
		}
	}

	c.isDirty = true
	c.writeAt(content, offset)
	c.Size = int64(len(c.content))

	return nil
}

// TruncateTo reduces content size to specified length. If necessary,
// it fetches all content from remote first.
func (c *ContentReadWriter) TruncateTo(size uint64) error {
	if c.needSync() {
		if err := c.ReadAll(); err != nil {
			return err
		}
	}

	s := int(size)
	switch {
	case s < len(c.content):
		// specified size less than size of file, so remove all content over size
		c.content = c.content[:size]
	case s > len(c.content):
		// specified size greater same as size of file, so add empty padding to
		// existing content
		c.content = append(c.content, make([]byte, s-len(c.content))...)
	case s == len(c.content):
		// specified size is same as size of file, so nothing to be done
	}

	c.Size = int64(len(c.content))

	return c.Save(true)
}

// Save writes locally saved content to remote.
func (c *ContentReadWriter) Save(force bool) error {
	if !c.needSave() && !force {
		return nil
	}

	return c.writeContentToRemote(c.content)
}

// Reset removes locally saved content.
func (c *ContentReadWriter) Reset() {
	c.isDirty = false
	c.content = nil
}

///// private

// needSync returns if locally saved content is not the same size of file on
// remote.
func (c *ContentReadWriter) needSync() bool {
	return c.Size != int64(len(c.content))
}

// needSave returns if new changes have been added to local content, but hasn't
// been saved to remote yet.
func (c *ContentReadWriter) needSave() bool {
	return c.isDirty
}

// writeAt writes specified byte slice to locally saved content slice at specified
// offset. If local content slice doesn't have enough space, it addes the
// required space first before calling copy().
func (c *ContentReadWriter) writeAt(content []byte, offset int64) int {
	var newLen = len(content) + int(offset)
	if len(c.content) < newLen {
		padding := make([]byte, newLen-len(c.content))
		c.content = append(c.content, padding...)
	}

	return copy(c.content[offset:], content)
}

// writeContentToRemote saves specified byte slice to remote.
func (c *ContentReadWriter) writeContentToRemote(content []byte) error {
	c.isDirty = false
	return c.remote.WriteFile(*c.Path, content)
}
