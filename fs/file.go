package fs

import (
	"io"

	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/transport"
)

type File struct {
	// Entry is generic structure that contains commonality between File and Dir.
	*Entry

	////// Node#RWLock protects the fields below.

	// IsDirty indicates if File has been written to, but not yet been synced
	// with remote.
	IsDirty bool

	// Content is the remotely fetched contents of the File.
	Content []byte
}

func NewFile(n *Entry) *File {
	return &File{Entry: n, Content: []byte{}}
}

func (f *File) ReadAt(offset int64) ([]byte, error) {
	f.Lock()
	defer f.Unlock()

	// fetch from remote is no content
	if len(f.Content) == 0 {
		content, err := f.getContentFromRemote()
		if err != nil {
			return nil, err
		}

		f.Content = content
	}

	// check offset only after fetching from remote
	if offset > int64(len(f.Content)) {
		return nil, io.EOF
	}

	return f.Content[offset:], nil
}

func (f *File) Create() error {
	return f.Flush()
}

func (f *File) WriteAt(content []byte, offset int64) {
	f.Lock()
	defer f.Unlock()

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
}

func (f *File) TruncateTo(size uint64) error {
	f.Lock()
	defer f.Unlock()

	if size > uint64(len(f.Content)) {
		return io.EOF
	}

	f.Content = f.Content[:size]

	return f.writeContentToRemote(f.Content)
}

func (f *File) Flush() error {
	f.Lock()
	defer f.Unlock()

	return f.writeContentToRemote(f.Content)
}

func (f *File) Sync() error {
	f.Lock()
	defer f.Unlock()

	return f.writeContentToRemote(f.Content)
}

///// Node interface

func (f *File) GetType() fuseutil.DirentType {
	return fuseutil.DT_File
}

///// Helpers

func (f *File) writeContentToRemote(content []byte) error {
	f.IsDirty = false

	req := struct {
		Path    string
		Content []byte
	}{
		Path:    f.RemotePath,
		Content: content,
	}
	var res int

	return f.Transport.Trip("fs.writeFile", req, &res)
}

func (f *File) getContentFromRemote() ([]byte, error) {
	req := struct{ Path string }{f.RemotePath}
	res := transport.FsReadFileRes{}
	if err := f.Trip("fs.readFile", req, &res); err != nil {
		return []byte{}, err
	}

	return res.Content, nil
}
