package fuseklient

import (
	"errors"
	"io"
	"koding/fuseklient/transport"
)

const (
	DefaultBlockSize = 4096 * 10
)

var (
	ErrCreateOnNotEmpty = errors.New("Create called on file sized > 0.")
)

type remote interface {
	ReadFileAt(string, int64, int64) (*transport.ReadFileRes, error)
	WriteFile(string, []byte) error
}

type ContentReadWriter struct {
	remote

	Path string
	Size int64

	BlockSize int64

	isDirty bool
	content []byte
}

func NewContentReadWriter(t remote, path string, size int64) *ContentReadWriter {
	return &ContentReadWriter{
		remote:    t,
		Path:      path,
		Size:      size,
		BlockSize: DefaultBlockSize,
		isDirty:   false,
		content:   nil,
	}
}

func (c *ContentReadWriter) Create() error {
	if c.Size > 0 {
		return ErrCreateOnNotEmpty
	}

	return c.writeContentToRemote(c.content)
}

func (c *ContentReadWriter) ReadAt(p []byte, offset int64) (int, error) {
	if offset >= c.Size {
		return 0, io.EOF
	}

	// everything is fetched from remote already, so return from it
	if int64(len(c.content)) == c.Size {
		copied := copy(p, c.content[offset:])
		return copied, nil
	}

	resp, err := c.remote.ReadFileAt(c.Path, offset, int64(len(p)))
	if err != nil {
		return 0, err
	}

	// TODO: save resp.Content to c.content if curPos is at offset

	copied := copy(p, resp.Content)

	return copied, nil
}

func (c *ContentReadWriter) ResetAndRead() error {
	c.Reset()
	return c.ReadAll()
}

func (c *ContentReadWriter) ReadAll() error {
	// everything is fetched from remote already, so return
	if int64(len(c.content)) == c.Size {
		return nil
	}

	var offset int64 = 0
	for offset < c.Size {
		resp, err := c.remote.ReadFileAt(c.Path, offset, c.BlockSize)
		if err != nil {
			return err
		}

		n := c.writeAt(resp.Content, offset)
		offset += int64(n)
	}

	// TODO: what is this doing here?
	//if offset == 0 {
	//  c.content = c.content[0:len(content)]
	//}

	return nil
}

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

// TruncateTo reduces file contents to specified length.
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

	return c.Save()
}

func (c *ContentReadWriter) Save() error {
	if c.needSave() {
		return c.writeContentToRemote(c.content)
	}

	return nil
}

func (c *ContentReadWriter) Reset() {
	c.isDirty = false
	c.content = nil
}

///// private

func (c *ContentReadWriter) needSync() bool {
	return c.Size != int64(len(c.content))
}

func (c *ContentReadWriter) needSave() bool {
	return c.isDirty
}

func (c *ContentReadWriter) writeAt(content []byte, offset int64) int {
	var newLen = len(content) + int(offset)
	if len(c.content) < newLen {
		padding := make([]byte, newLen-len(c.content))
		c.content = append(c.content, padding...)
	}

	return copy(c.content[offset:], content)
}

func (c *ContentReadWriter) writeContentToRemote(content []byte) error {
	c.isDirty = false
	return c.remote.WriteFile(c.Path, content)
}
