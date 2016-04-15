package transport

import (
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

const (
	// defaultLongTellTimeout is the default timeout longTellMethods use.
	defaultLongTellTimeout = 5 * time.Second
)

var (
	// longTimeoutMethods is the timeouts that specific kite method calls over
	// the network will take to timeout. This should be large enough as to allow
	// long requests to be sent over the kite callback protocol, but also small
	// enough to allow the network error to be presented to the user in the event
	// of network disruptions.
	//
	// If left too large, the Kernel (in OSX, for example) will fail fs ops by printing
	// "Socket is not connected" to the user. So if that message is seen, this value
	// likely needs to be lowered.
	// The klient methods to use a large timeout for.
	longTimeoutMethods = map[string]time.Duration{
		"exec": defaultLongTellTimeout,
	}
)

// Teller is the interface usually implemented by kite.Client.
type Teller interface {
	Tell(string, ...interface{}) (*dnode.Partial, error)
	TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error)
}

// RemoteTransport is a Transport that uses klient on user VM to communicate.
type RemoteTransport struct {
	Client Teller

	// RemotePath is the full path to mounted dir on user VM.
	RemotePath string

	// The timeout trip() uses for TellWithTimeout. If left empty, a zero timeout
	// is used, achieving the same result as tell(), ie no timeout.
	TellTimeout time.Duration

	// IgnoreDirs are dirs that are ignored for performance purposes, ie .git
	// .svn etc.
	IgnoreDirs []string

	BlockSize int64
}

// NewRemoteTransport initializes RemoteTransport with kite connection.
func NewRemoteTransport(c Teller, t time.Duration, p string) (*RemoteTransport, error) {
	return &RemoteTransport{
		Client:      c,
		RemotePath:  p,
		TellTimeout: t,
		IgnoreDirs:  defaultDirIgnoreList,
	}, nil
}

// CreateDir (recursively) creates dir with specified name. It does not send
// specified mode to remote.
func (r *RemoteTransport) CreateDir(path string, _ os.FileMode) error {
	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      r.fullPath(path),
		Recursive: true,
	}
	var res bool
	return r.trip("fs.createDirectory", req, &res)
}

// ReadDir returns entries of the dir at specified path. It ignores dirs
// specified in RemoteTransport#IgnoreDirs.
func (r *RemoteTransport) ReadDir(path string, re bool) (*ReadDirRes, error) {
	req := struct {
		Path          string
		Recursive     bool
		IgnoreFolders []string
	}{
		Path:          r.fullPath(path),
		Recursive:     re,
		IgnoreFolders: r.IgnoreDirs,
	}
	res := &ReadDirRes{}
	if err := r.trip("fs.readDirectory", req, &res); err != nil {
		return nil, err
	}

	// remove remote path prefix from entries
	for i, entry := range res.Files {
		entry.FullPath = r.relativePath(entry.FullPath)
		res.Files[i] = entry
	}

	return res, nil
}

func (r *RemoteTransport) Rename(oldPath, newPath string) error {
	req := struct{ OldPath, NewPath string }{
		OldPath: r.fullPath(oldPath),
		NewPath: r.fullPath(newPath),
	}
	var res bool
	return r.trip("fs.rename", req, res)
}

func (r *RemoteTransport) Remove(path string) error {
	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      r.fullPath(path),
		Recursive: true,
	}
	var res bool
	return r.trip("fs.remove", req, &res)
}

func (r *RemoteTransport) ReadFile(path string) (*ReadFileRes, error) {
	req := struct{ Path string }{r.fullPath(path)}
	res := &ReadFileRes{}
	if err := r.trip("fs.readFile", req, &res); err != nil {
		return nil, err
	}

	return res, nil
}

func (r *RemoteTransport) ReadFileAt(path string, offset, blockSize int64) (*ReadFileRes, error) {
	req := struct {
		Path      string
		Offset    int64
		BlockSize int64
	}{
		r.fullPath(path),
		offset,
		r.BlockSize,
	}
	res := &ReadFileRes{}
	if err := r.trip("fs.readFile", req, &res); err != nil {
		return nil, err
	}

	return res, nil
}

func (r *RemoteTransport) WriteFile(path string, content []byte) error {
	req := struct {
		Path    string
		Content []byte
	}{
		Path:    r.fullPath(path),
		Content: content,
	}
	var res int
	return r.trip("fs.writeFile", req, &res)
}

func (r *RemoteTransport) Exec(cmd string) (*ExecRes, error) {
	req := struct{ Command string }{cmd}
	res := &ExecRes{}
	if err := r.trip("exec", req, &res); err != nil {
		return nil, err
	}

	return res, nil
}

func (r *RemoteTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	req := struct{ Path string }{r.fullPath(path)}
	res := &GetDiskInfoRes{}
	if err := r.trip("fs.getDiskInfo", req, &res); err != nil {
		if kiteErr, ok := err.(*kite.Error); ok && kiteErr.Type != "methodNotFound" {
			return nil, err
		}
	}

	return res, nil
}

func (r *RemoteTransport) GetInfo(path string) (*GetInfoRes, error) {
	req := struct{ Path string }{r.fullPath(path)}
	res := &GetInfoRes{}
	if err := r.trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	// remove disk path prefix
	res.FullPath = r.relativePath(res.FullPath)

	return res, nil
}

// SetIgnoreDirs sets specified dirs to ignore list.
func (r *RemoteTransport) SetIgnoreDirs(dirs []string) {
	r.IgnoreDirs = dirs
}

func (r *RemoteTransport) GetRemotePath() string {
	return r.RemotePath
}

///// Helpers

// fullPath prefixes remoate path with the specified path. This is used to
// specify the path in requests.
func (r *RemoteTransport) fullPath(path string) string {
	return filepath.Join(r.RemotePath, path)
}

// relativePath removes remote path prefix from specified path. This is used
// when cleaning up responses.
func (r *RemoteTransport) relativePath(path string) string {
	return strings.TrimPrefix(path, r.RemotePath)
}

// trip is a generic method for communication. It accepts `req` to pass args
// to kite and `res` to store unmarshalled response from kite.
//
// If the method timeouts out, then we return syscall.ECONNREFUSED so it'll be
// shown to user by the kernel.
func (r *RemoteTransport) trip(methodName string, req interface{}, res interface{}) error {
	// Adjust our timeout for specific methods. Some methods always need a long
	// timeout.
	timeout := getTellTimout(methodName, r.TellTimeout)

	raw, err := r.Client.TellWithTimeout(methodName, timeout, req)
	if err != nil {
		if IsKiteConnectionErr(err) {
			return syscall.ECONNREFUSED
		}
		return err
	}

	return raw.Unmarshal(&res)
}

// getTellTimeout returns the timeout to use for the given method. Some klient methods
// need a shorter duration, some longer. This function encapsulates that deciding
// logic into a single function.
//
// If the given method is not adjusted by this method, it returns the given default
// timeout.
func getTellTimout(methodName string, notLongTimeout time.Duration) time.Duration {
	timeout, ok := longTimeoutMethods[methodName]
	if !ok {
		timeout = notLongTimeout
	}

	return timeout
}

///// Kite error checkers

func IsKiteMethodNotFoundErr(err error) bool {
	kiteErr, ok := err.(*kite.Error)
	return ok && kiteErr.Type != "methodNotFound"
}

func IsKiteConnectionErr(err error) bool {
	kiteError, ok := err.(*kite.Error)
	switch {
	case !ok:
		return false
	case kiteError.Type == "timeout":
		return true
	case kiteError.Type == "sendError":
		return true
	default:
		return false
	}
}
