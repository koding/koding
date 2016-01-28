package transport

import (
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

const (
	kiteName    = "fuseklient"
	kiteVersion = "0.0.1"
	kiteTimeout = 10 * time.Second
)

// KlientTransport is a Transport using Klient on user VM.
type KlientTransport struct {
	Client *kite.Client

	// RemotePath is path to dir in user VM to be mounted locally.
	RemotePath string

	// The timeout trip() uses for TellWithTimeout. If left empty, a zero timeout is
	// used, achieving the same result as Tell(), ie no timeout.
	TellTimeout time.Duration

	IgnoreDirs []string
}

// NewKlientTransport initializes KlientTransport with Klient connection.
func NewKlientTransport(c *kite.Client, t time.Duration, r string) (*KlientTransport, error) {
	return &KlientTransport{
		Client:      c,
		TellTimeout: t,
		IgnoreDirs:  defaultDirIgnoreList,
	}, nil
}

// CreateDir (recursively) creates dir with specified name. Note, it does
// not send specified mode to remote.
func (k *KlientTransport) CreateDir(path string, _ os.FileMode) error {
	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      k.fullPath(path),
		Recursive: true,
	}
	var res bool
	return k.trip("fs.createDirectory", req, &res)
}

// ReadDir returns entries of the dir at specified path. Note, it ignores
// folders specified in KlientTransport#IgnoreDirs.
func (k *KlientTransport) ReadDir(path string, r bool) (*ReadDirRes, error) {
	req := struct {
		Path          string
		Recursive     bool
		IgnoreFolders []string
	}{
		Path:          k.fullPath(path),
		Recursive:     r,
		IgnoreFolders: k.IgnoreDirs,
	}
	res := &ReadDirRes{}
	if err := k.trip("fs.readDirectory", req, &res); err != nil {
		return res, err
	}

	// remove remote path prefix from entries
	for i, entry := range res.Files {
		entry.FullPath = k.relativePath(entry.FullPath)
		res.Files[i] = entry
	}

	return res, nil
}

func (k *KlientTransport) Rename(oldPath, newPath string) error {
	req := struct{ OldPath, NewPath string }{
		OldPath: k.fullPath(oldPath),
		NewPath: k.fullPath(newPath),
	}
	var res bool
	return k.trip("fs.rename", req, res)
}

func (k *KlientTransport) Remove(path string) error {
	req := struct {
		Path      string
		Recursive bool
	}{
		Path:      k.fullPath(path),
		Recursive: true,
	}
	var res bool
	return k.trip("fs.remove", req, &res)
}

func (k *KlientTransport) ReadFile(path string) (*ReadFileRes, error) {
	req := struct{ Path string }{k.fullPath(path)}
	res := &ReadFileRes{}
	if err := k.trip("fs.readFile", req, &res); err != nil {
		return res, err
	}

	return res, nil
}

func (k *KlientTransport) WriteFile(path string, content []byte) error {
	req := struct {
		Path    string
		Content []byte
	}{
		Path:    k.fullPath(path),
		Content: content,
	}
	var res int

	return k.trip("fs.writeFile", req, &res)
}

func (k *KlientTransport) Exec(cmd string) (*ExecRes, error) {
	req := struct{ Command string }{cmd}
	res := &ExecRes{}
	if err := k.trip("exec", req, &res); err != nil {
		return nil, err
	}

	return res, nil
}

func (k *KlientTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	req := struct{ Path string }{k.fullPath(path)}
	res := &GetDiskInfoRes{}

	if err := k.trip("fs.getDiskInfo", req, &res); err != nil {
		if kiteErr, ok := err.(*kite.Error); ok && kiteErr.Type != "methodNotFound" {
			return nil, err
		}
	}

	return res, nil
}

func (k *KlientTransport) GetInfo(path string) (*GetInfoRes, error) {
	req := struct{ Path string }{k.fullPath(path)}
	res := &GetInfoRes{}

	if err := k.trip("fs.getInfo", req, &res); err != nil {
		return nil, err
	}

	// remove disk path prefix
	res.FullPath = k.relativePath(res.FullPath)

	return res, nil
}

///// Helpers

// fullPath prefixes remoate path with the specified path. This is used to
// specify the path in requests.
func (k *KlientTransport) fullPath(path string) string {
	return filepath.Join(k.RemotePath, path)
}

// relativePath removes remote path prefix from specified path. This is used
// when cleaning up responses.
func (k *KlientTransport) relativePath(path string) string {
	return strings.TrimPrefix(path, k.RemotePath)
}

// trip is a generic method for communication. It accepts `req` to pass args
// to Klient and `res` to store unmarshalled response from Klient.
//
// If the method timeouts out, then we return syscall.ECONNREFUSED so it'll be
// shown to user by the kernel.
func (k *KlientTransport) trip(methodName string, req interface{}, res interface{}) error {
	raw, err := k.Client.TellWithTimeout(methodName, k.TellTimeout, req)
	if err != nil {
		if kiteError, ok := err.(*kite.Error); ok && kiteError.Type == "timeout" {
			return syscall.ECONNREFUSED
		}

		return err
	}

	return raw.Unmarshal(&res)
}
