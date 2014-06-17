package sftp

import (
	"io"
	"os"
	"path"
	"sync"
	"time"

	"github.com/kr/fs"

	"code.google.com/p/go.crypto/ssh"
)

// New creates a new SFTP client on conn.
func NewClient(conn *ssh.Client) (*Client, error) {
	s, err := conn.NewSession()
	if err != nil {
		return nil, err
	}
	if err := s.RequestSubsystem("sftp"); err != nil {
		return nil, err
	}
	pw, err := s.StdinPipe()
	if err != nil {
		return nil, err
	}
	pr, err := s.StdoutPipe()
	if err != nil {
		return nil, err
	}
	sftp := &Client{
		w: pw,
		r: pr,
	}
	if err := sftp.sendInit(); err != nil {
		return nil, err
	}
	return sftp, sftp.recvVersion()
}

// Client represents an SFTP session on a *ssh.ClientConn SSH connection.
// Multiple Clients can be active on a single SSH connection, and a Client
// may be called concurrently from multiple Goroutines.
//
// Client implements the github.com/kr/fs.FileSystem interface.
type Client struct {
	w      io.WriteCloser
	r      io.Reader
	mu     sync.Mutex // locks mu and seralises commands to the server
	nextid uint32
}

// Close closes the SFTP session.
func (c *Client) Close() error { return c.w.Close() }

// Create creates the named file mode 0666 (before umask), truncating it if
// it already exists. If successful, methods on the returned File can be
// used for I/O; the associated file descriptor has mode O_RDWR.
func (c *Client) Create(path string) (*File, error) {
	return c.open(path, flags(os.O_RDWR|os.O_CREATE|os.O_TRUNC))
}

func (c *Client) sendInit() error {
	type packet struct {
		Type       byte
		Version    uint32
		Extensions []struct {
			Name, Data string
		}
	}
	return sendPacket(c.w, packet{
		Type:    ssh_FXP_INIT,
		Version: 3, // http://tools.ietf.org/html/draft-ietf-secsh-filexfer-02
	})
}

// returns the current value of c.nextid and increments it
// callers is expected to hold c.mu
func (c *Client) nextId() uint32 {
	v := c.nextid
	c.nextid++
	return v
}

func (c *Client) recvVersion() error {
	typ, _, err := recvPacket(c.r)
	if err != nil {
		return err
	}
	if typ != ssh_FXP_VERSION {
		return &unexpectedPacketErr{ssh_FXP_VERSION, typ}
	}
	return nil
}

// Walk returns a new Walker rooted at root.
func (c *Client) Walk(root string) *fs.Walker {
	return fs.WalkFS(root, c)
}

// ReadDir reads the directory named by dirname and returns a list of
// directory entries.
func (c *Client) ReadDir(p string) ([]os.FileInfo, error) {
	handle, err := c.opendir(p)
	if err != nil {
		return nil, err
	}
	defer c.close(handle) // this has to defer earlier than the lock below
	var attrs []os.FileInfo
	c.mu.Lock()
	defer c.mu.Unlock()
	var done = false
	for !done {
		type packet struct {
			Type   byte
			Id     uint32
			Handle string
		}
		id := c.nextId()
		typ, data, err1 := c.sendRequest(packet{
			Type:   ssh_FXP_READDIR,
			Id:     id,
			Handle: handle,
		})
		if err1 != nil {
			err = err1
			done = true
			break
		}
		switch typ {
		case ssh_FXP_NAME:
			sid, data := unmarshalUint32(data)
			if sid != id {
				return nil, &unexpectedIdErr{id, sid}
			}
			count, data := unmarshalUint32(data)
			for i := uint32(0); i < count; i++ {
				var filename string
				filename, data = unmarshalString(data)
				_, data = unmarshalString(data) // discard longname
				var attr *attr
				attr, data = unmarshalAttrs(data)
				if filename == "." || filename == ".." {
					continue
				}
				attr.name = path.Base(filename)
				attrs = append(attrs, attr)
			}
		case ssh_FXP_STATUS:
			// TODO(dfc) scope warning!
			err = eofOrErr(unmarshalStatus(id, data))
			done = true
		default:
			return nil, unimplementedPacketErr(typ)
		}
	}
	if err == io.EOF {
		err = nil
	}
	return attrs, err
}
func (c *Client) opendir(path string) (string, error) {
	type packet struct {
		Type byte
		Id   uint32
		Path string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type: ssh_FXP_OPENDIR,
		Id:   id,
		Path: path,
	})
	if err != nil {
		return "", err
	}
	switch typ {
	case ssh_FXP_HANDLE:
		sid, data := unmarshalUint32(data)
		if sid != id {
			return "", &unexpectedIdErr{id, sid}
		}
		handle, _ := unmarshalString(data)
		return handle, nil
	case ssh_FXP_STATUS:
		return "", unmarshalStatus(id, data)
	default:
		return "", unimplementedPacketErr(typ)
	}
}

func (c *Client) Lstat(p string) (os.FileInfo, error) {
	type packet struct {
		Type byte
		Id   uint32
		Path string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type: ssh_FXP_LSTAT,
		Id:   id,
		Path: p,
	})
	if err != nil {
		return nil, err
	}
	switch typ {
	case ssh_FXP_ATTRS:
		sid, data := unmarshalUint32(data)
		if sid != id {
			return nil, &unexpectedIdErr{id, sid}
		}
		attr, _ := unmarshalAttrs(data)
		attr.name = path.Base(p)
		return attr, nil
	case ssh_FXP_STATUS:
		return nil, unmarshalStatus(id, data)
	default:
		return nil, unimplementedPacketErr(typ)
	}
}

// Chtimes changes the access and modification times of the named file.
func (c *Client) Chtimes(path string, atime time.Time, mtime time.Time) error {
	type packet struct {
		Type  byte
		Id    uint32
		Path  string
		Flags uint32
		Atime uint32
		Mtime uint32
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:  ssh_FXP_SETSTAT,
		Id:    id,
		Path:  path,
		Flags: ssh_FILEXFER_ATTR_ACMODTIME,
		Atime: uint32(atime.Unix()),
		Mtime: uint32(mtime.Unix()),
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

// Open opens the named file for reading. If successful, methods on the
// returned file can be used for reading; the associated file descriptor
// has mode O_RDONLY.
func (c *Client) Open(path string) (*File, error) {
	return c.open(path, flags(os.O_RDONLY))
}

// OpenFile is the generalized open call; most users will use Open or
// Create instead. It opens the named file with specified flag (O_RDONLY
// etc.). If successful, methods on the returned File can be used for I/O.
func (c *Client) OpenFile(path string, f int) (*File, error) {
	return c.open(path, flags(f))
}

func (c *Client) open(path string, pflags uint32) (*File, error) {
	type packet struct {
		Type   byte
		Id     uint32
		Path   string
		Pflags uint32
		Flags  uint32 // ignored
		Size   uint64 // ignored
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:   ssh_FXP_OPEN,
		Id:     id,
		Path:   path,
		Pflags: pflags,
	})
	if err != nil {
		return nil, err
	}
	switch typ {
	case ssh_FXP_HANDLE:
		sid, data := unmarshalUint32(data)
		if sid != id {
			return nil, &unexpectedIdErr{id, sid}
		}
		handle, _ := unmarshalString(data)
		return &File{c: c, path: path, handle: handle}, nil
	case ssh_FXP_STATUS:
		return nil, unmarshalStatus(id, data)
	default:
		return nil, unimplementedPacketErr(typ)
	}
}

// readAt reads len(buf) bytes from the remote file indicated by handle starting
// from offset.
func (c *Client) readAt(handle string, offset uint64, buf []byte) (uint32, error) {
	type packet struct {
		Type   byte
		Id     uint32
		Handle string
		Offset uint64
		Len    uint32
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:   ssh_FXP_READ,
		Id:     id,
		Handle: handle,
		Offset: offset,
		Len:    uint32(len(buf)),
	})
	if err != nil {
		return 0, err
	}
	switch typ {
	case ssh_FXP_DATA:
		sid, data := unmarshalUint32(data)
		if sid != id {
			return 0, &unexpectedIdErr{id, sid}
		}
		l, data := unmarshalUint32(data)
		n := copy(buf, data[:l])
		return uint32(n), nil
	case ssh_FXP_STATUS:
		return 0, eofOrErr(unmarshalStatus(id, data))
	default:
		return 0, unimplementedPacketErr(typ)
	}
}

// close closes a handle handle previously returned in the response
// to SSH_FXP_OPEN or SSH_FXP_OPENDIR. The handle becomes invalid
// immediately after this request has been sent.
func (c *Client) close(handle string) error {
	type packet struct {
		Type   byte
		Id     uint32
		Handle string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:   ssh_FXP_CLOSE,
		Id:     id,
		Handle: handle,
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

func (c *Client) fstat(handle string) (*attr, error) {
	type packet struct {
		Type   byte
		Id     uint32
		Handle string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:   ssh_FXP_FSTAT,
		Id:     id,
		Handle: handle,
	})
	if err != nil {
		return nil, err
	}
	switch typ {
	case ssh_FXP_ATTRS:
		sid, data := unmarshalUint32(data)
		if sid != id {
			return nil, &unexpectedIdErr{id, sid}
		}
		attr, _ := unmarshalAttrs(data)
		return attr, nil
	case ssh_FXP_STATUS:
		return nil, unmarshalStatus(id, data)
	default:
		return nil, unimplementedPacketErr(typ)
	}
}

// Join joins any number of path elements into a single path, adding a
// separating slash if necessary. The result is Cleaned; in particular, all
// empty strings are ignored.
func (c *Client) Join(elem ...string) string { return path.Join(elem...) }

// Remove removes the specified file or directory. An error will be returned if no
// file or directory with the specified path exists, or if the specified directory
// is not empty.
func (c *Client) Remove(path string) error {
	err := c.removeFile(path)
	if status, ok := err.(*StatusError); ok && status.Code == ssh_FX_FAILURE {
		err = c.removeDirectory(path)
	}
	return err
}

func (c *Client) removeFile(path string) error {
	type packet struct {
		Type     byte
		Id       uint32
		Filename string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:     ssh_FXP_REMOVE,
		Id:       id,
		Filename: path,
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

func (c *Client) removeDirectory(path string) error {
	type packet struct {
		Type byte
		Id   uint32
		Path string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type: ssh_FXP_RMDIR,
		Id:   id,
		Path: path,
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

// Rename renames a file.
func (c *Client) Rename(oldname, newname string) error {
	type packet struct {
		Type             byte
		Id               uint32
		Oldpath, Newpath string
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:    ssh_FXP_RENAME,
		Id:      id,
		Oldpath: oldname,
		Newpath: newname,
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

func (c *Client) sendRequest(p interface{}) (byte, []byte, error) {
	if err := sendPacket(c.w, p); err != nil {
		return 0, nil, err
	}
	return recvPacket(c.r)
}

// writeAt writes len(buf) bytes from the remote file indicated by handle starting
// from offset.
func (c *Client) writeAt(handle string, offset uint64, buf []byte) (uint32, error) {
	type packet struct {
		Type   byte
		Id     uint32
		Handle string
		Offset uint64
		Length uint32
		Data   []byte
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type:   ssh_FXP_WRITE,
		Id:     id,
		Handle: handle,
		Offset: offset,
		Length: uint32(len(buf)),
		Data:   buf,
	})
	if err != nil {
		return 0, err
	}
	switch typ {
	case ssh_FXP_STATUS:
		if err := okOrErr(unmarshalStatus(id, data)); err != nil {
			return 0, nil
		}
		return uint32(len(buf)), nil
	default:
		return 0, unimplementedPacketErr(typ)
	}
}

// Creates the specified directory. An error will be returned if a file or
// directory with the specified path already exists, or if the directory's
// parent folder does not exist (the method cannot create complete paths).
func (c *Client) Mkdir(path string) error {
	type packet struct {
		Type  byte
		Id    uint32
		Path  string
		Flags uint32 // ignored
		Size  uint64 // ignored
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	id := c.nextId()
	typ, data, err := c.sendRequest(packet{
		Type: ssh_FXP_MKDIR,
		Id:   id,
		Path: path,
	})
	if err != nil {
		return err
	}
	switch typ {
	case ssh_FXP_STATUS:
		return okOrErr(unmarshalStatus(id, data))
	default:
		return unimplementedPacketErr(typ)
	}
}

// File represents a remote file.
type File struct {
	c      *Client
	path   string
	handle string
	offset uint64 // current offset within remote file
}

// Close closes the File, rendering it unusable for I/O. It returns an
// error, if any.
func (f *File) Close() error {
	return f.c.close(f.handle)
}

// Read reads up to len(b) bytes from the File. It returns the number of
// bytes read and an error, if any. EOF is signaled by a zero count with
// err set to io.EOF.
func (f *File) Read(b []byte) (int, error) {
	var read int
	for len(b) > 0 {
		n, err := f.c.readAt(f.handle, f.offset, b[:min(len(b), maxWritePacket)])
		f.offset += uint64(n)
		read += int(n)
		if err != nil {
			return read, err
		}
		b = b[n:]
	}
	return read, nil
}

// Stat returns the FileInfo structure describing file. If there is an
// error.
func (f *File) Stat() (os.FileInfo, error) {
	fi, err := f.c.fstat(f.handle)
	if err == nil {
		fi.name = path.Base(f.path)
	}
	return fi, err
}

// clamp writes to less than 32k
const maxWritePacket = 1 << 15

// Write writes len(b) bytes to the File. It returns the number of bytes
// written and an error, if any. Write returns a non-nil error when n !=
// len(b).
func (f *File) Write(b []byte) (int, error) {
	var written int
	for len(b) > 0 {
		n, err := f.c.writeAt(f.handle, f.offset, b[:min(len(b), maxWritePacket)])
		f.offset += uint64(n)
		written += int(n)
		if err != nil {
			return written, err
		}
		b = b[n:]
	}
	return written, nil
}

func min(a, b int) int {
	if a > b {
		return b
	}
	return a
}

// okOrErr returns nil if Err.Code is SSH_FX_OK, otherwise it returns the error.
func okOrErr(err error) error {
	if err, ok := err.(*StatusError); ok && err.Code == ssh_FX_OK {
		return nil
	}
	return err
}

func eofOrErr(err error) error {
	if err, ok := err.(*StatusError); ok && err.Code == ssh_FX_EOF {
		return io.EOF
	}
	return err
}

func unmarshalStatus(id uint32, data []byte) error {
	sid, data := unmarshalUint32(data)
	if sid != id {
		return &unexpectedIdErr{id, sid}
	}
	code, data := unmarshalUint32(data)
	msg, data := unmarshalString(data)
	lang, _ := unmarshalString(data)
	return &StatusError{
		Code: code,
		msg:  msg,
		lang: lang,
	}
}

// flags converts the flags passed to OpenFile into ssh flags.
// Unsupported flags are ignored.
func flags(f int) uint32 {
	var out uint32
	switch f & os.O_WRONLY {
	case os.O_WRONLY:
		out |= ssh_FXF_WRITE
	case os.O_RDONLY:
		out |= ssh_FXF_READ
	}
	if f&os.O_RDWR == os.O_RDWR {
		out |= ssh_FXF_READ | ssh_FXF_WRITE
	}
	if f&os.O_APPEND == os.O_APPEND {
		out |= ssh_FXF_APPEND
	}
	if f&os.O_CREATE == os.O_CREATE {
		out |= ssh_FXF_CREAT
	}
	if f&os.O_TRUNC == os.O_TRUNC {
		out |= ssh_FXF_TRUNC
	}
	if f&os.O_EXCL == os.O_EXCL {
		out |= ssh_FXF_EXCL
	}
	return out
}
