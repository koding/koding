package transport

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/user"
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
}

// NewKlientTransport initializes KlientTransport with Klient connection.
func NewKlientTransport(klientIP string) (*KlientTransport, error) {
	k := kite.New(kiteName, kiteVersion)

	kiteClient := k.NewClient(fmt.Sprintf("http://%s:56789/kite", klientIP))

	// os/user has issues with cross compiling, so we may want to use
	// the following library instead:
	//
	// 	https://github.com/mitchellh/go-homedir
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadFile(fmt.Sprintf(
		"%s/.fuseklient/keys/%s.kite.key", usr.HomeDir, klientIP,
	))
	if err != nil {
		return nil, err
	}

	kiteClient.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  strings.TrimSpace(string(data)),
	}
	kiteClient.Reconnect = true

	if err := kiteClient.DialTimeout(kiteTimeout); err != nil {
		return nil, err
	}

	return &KlientTransport{Client: kiteClient}, nil
}

// CreateDir (recursively) creates dir with specified name and mode. It does
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

// ReadDir returns entries of the dir at specified path. It takes slice of dir
// names as strings to ignore from listing.
func (k *KlientTransport) ReadDir(path string, recursive bool, ignoreFolders []string) (*ReadDirRes, error) {
	req := struct {
		Path          string
		Recursive     bool
		IgnoreFolders []string
	}{
		Path:          k.fullPath(path),
		Recursive:     true,
		IgnoreFolders: ignoreFolders,
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

// Rename changes name of the entry from specified old to new name.
func (k *KlientTransport) Rename(oldPath, newPath string) error {
	req := struct{ OldPath, NewPath string }{
		OldPath: k.fullPath(oldPath),
		NewPath: k.fullPath(newPath),
	}
	var res bool
	return k.trip("fs.rename", req, res)
}

// Remove (recursively) removes the entries in the specificed path.
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

// ReadFile reads file at specificed path and return its contents.
func (k *KlientTransport) ReadFile(path string) (*ReadFileRes, error) {
	req := struct{ Path string }{k.fullPath(path)}
	res := &ReadFileRes{}
	if err := k.trip("fs.readFile", req, &res); err != nil {
		return res, err
	}

	return res, nil
}

// WriteFile writes file at specificed path with data.
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

// Exec runs specified command. Note, it doesn't set the path from where it
// executes the command; by default it'll the location from which klient runs.
func (k *KlientTransport) Exec(cmd string) (*ExecRes, error) {
	req := struct{ Command string }{cmd}
	res := &ExecRes{}
	if err := k.trip("exec", req, &res); err != nil {
		return nil, err
	}

	return res, nil
}

// GetDiskInfo returns disk info about the mount at the specified path. If a
// nested path is specified, it returns the top most mount.
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

// GetInfo returns info about the entry at specified path.
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
