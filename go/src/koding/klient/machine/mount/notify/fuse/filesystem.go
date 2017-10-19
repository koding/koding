package fuse

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"

	"koding/kites/config"
	konfig "koding/klient/config"
	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

// TODO(rjeczalik): add promise update ops, so attrs updates are served
// right away, without waiting for index update.

// TODO(rjeczalik): symlink support: add node.Entry.Nlink field and
// add support for in Unlink, ForgotInode and CreateSymlink methods.

// Builder provides a default notify.Builder for the FUSE filesystem.
var Builder notify.Builder = builder{}

type builder struct{}

// Build implements the notify.Builder interface.
func (builder) Build(opts *notify.BuildOpts) (notify.Notifier, error) {
	di, err := fs.Statfs(opts.CacheDir)
	if err != nil {
		return nil, err
	}

	o := &Options{
		Index:    opts.Index,
		Disk:     di,
		Cache:    opts.Cache,
		CacheDir: opts.CacheDir,
		Mount:    filepath.Base(opts.Path),
		MountDir: opts.Path,
		// intentionally separate env to not enable fuse logging
		// for regular kd debug
		Debug: konfig.Konfig.Mount.Debug >= 9,
		Log:   opts.Log,
	}

	if err := o.Valid(); err != nil {
		return nil, err
	}

	return NewFilesystem(o)
}

// Options configures FUSE filesystem.
type Options struct {
	Index    *index.Index   // metadata index
	Disk     *fs.DiskInfo   // filesystem information
	Cache    notify.Cache   // used to request cache updates
	CacheDir string         // path of the cache directory of the mount
	Mount    string         // name of the mount
	MountDir string         // path of the mount directory
	User     *config.User   // owner of the mount; if nil, config.CurrentUser is used
	Debug    bool           // turns on fuse debug logging
	Log      logging.Logger // log mount specific info
}

// Valid checks if provided options are valid.
func (o *Options) Valid() error {
	const sep = string(os.PathSeparator)

	if o.Index == nil {
		return errors.New("index is nil")
	}
	if o.Disk == nil {
		return errors.New("disk info is nil")
	}
	if o.Cache == nil {
		return errors.New("cache is nil")
	}
	if o.MountDir == "" {
		return errors.New("mount directory is empty")
	}
	if o.CacheDir == "" {
		return errors.New("cache directory is empty")
	}
	if !strings.HasSuffix(o.CacheDir, sep) {
		o.CacheDir = o.CacheDir + sep
	}
	if !strings.HasSuffix(o.MountDir, sep) {
		o.MountDir = o.MountDir + sep
	}

	return nil
}

func (o *Options) user() *config.User {
	if o.User != nil {
		return o.User
	}
	return config.CurrentUser
}

var _ fuseutil.FileSystem = (*Filesystem)(nil)

// Filesystem implements fuseutil.FileSystem.
//
// List operations are backend by index.
// Write and read operations are backed by cache,
// which is populated lazily by notify.Cache.
type Filesystem struct {
	// NotImplementedFileSystem provides stubs for the following methods:
	//
	//   - MkNode
	//   - CreateSymlink
	//   - ReadSymlink
	//
	fuseutil.NotImplementedFileSystem
	Options

	// Cancel the background context of all fuse operatins.
	cancel func()

	// Dynamic filesystem state.
	dirHandles  *DirHandleGroup
	fileHandles *FileHandleGroup
}

// FSWrapFunc allows to attach middlerares to underling filesystems.
type FSWrapFunc func(fuseutil.FileSystem) fuseutil.FileSystem

// NewFilesystem creates new Filesystem value.
func NewFilesystem(opts *Options, wraps ...FSWrapFunc) (*Filesystem, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	// Best-effort attempt of unmounting already existing mount.
	_ = Umount(opts.MountDir)

	// Ignore mkdir errors since it can return `file exists` error. Other errors
	// will cause FUSE backend fail.
	_ = os.MkdirAll(opts.MountDir, 0755)

	ctx, cancel := context.WithCancel(context.Background())

	gen := generator(MinHandleID)
	fs := &Filesystem{
		Options:     *opts,
		cancel:      cancel,
		dirHandles:  NewDirHandleGroup(opts.MountDir, gen),
		fileHandles: NewFileHandleGroup(gen),
	}

	// Attach additional filesystem wrappers if any.
	var fuseFS fuseutil.FileSystem = fs
	for _, wrap := range wraps {
		fuseFS = wrap(fuseFS)
	}

	cfg := fs.Config()

	// Debug information about filesystem.
	if opts.Log != nil {
		// User information.
		var userInfo string
		if u, err := user.Current(); err == nil {
			userInfo = fmt.Sprintf("%s, home: %s", u.Username, u.HomeDir)
		} else {
			userInfo = "cannot obtain user info: " + err.Error()
		}

		opts.Log.Info("Dir: %s; CacheDir: %s; Mounter: %s; Opts: %s; Usr: %s",
			opts.MountDir, opts.CacheDir, getFuserMountVer(), toOptionsString(cfg), userInfo)
	}

	m, err := fuse.Mount(opts.MountDir, fuseutil.NewFileSystemServer(fuseFS), cfg)
	if err != nil {
		return nil, err
	}

	go m.Join(ctx)

	return fs, nil
}

// Config constructs fuse configuration.
func (fs *Filesystem) Config() *fuse.MountConfig {
	var logger *log.Logger

	if fs.Debug {
		logger = log.New(os.Stderr, "fuse", log.LstdFlags|log.Lshortfile)
	}

	return &fuse.MountConfig{
		FSName:                  fs.Mount,
		VolumeName:              filepath.Base(fs.MountDir),
		DisableWritebackCaching: true,
		EnableVnodeCaching:      false,
		Options:                 fs.fuseOptions(),
		DebugLogger:             logger,
		ErrorLogger:             logger,
	}
}

func (fs *Filesystem) fuseOptions() map[string]string {
	if runtime.GOOS == "darwin" {
		return map[string]string{
			"local":       "",
			"allow_other": "",
			"auto_xattr":  "",
		}
	}

	// Try to determinate if user_allow_other option is enabled.
	file, err := os.Open("/etc/fuse.conf")
	if err != nil {
		if fs.Log != nil {
			fs.Log.Warning("Cannot read FUSE configuration: %v", err)
		}
		return map[string]string{}
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if strings.TrimSpace(scanner.Text()) == "user_allow_other" {
			return map[string]string{
				"allow_other": "",
			}
		}
	}

	if err := scanner.Err(); err != nil {
		if fs.Log != nil {
			fs.Log.Warning("Cannot parse FUSE configuration: %v", err)
		}
	}

	return map[string]string{}
}

// Close implements the notify.Notifier interface. It cleans up filesystem
// resources and tries to umount created device.
func (fs *Filesystem) Close() error {
	fs.cancel()
	fs.Destroy()

	return Umount(fs.MountDir)
}

// Umount unmounts FUSE filesystem.
func Umount(dir string) error {
	umountCmd := func(name string, args ...string) error {
		if p, err := exec.Command(name, args...).CombinedOutput(); err != nil {
			return fmt.Errorf("%s: %s", err, bytes.TrimSpace(p))
		}

		return nil
	}

	if runtime.GOOS == "linux" {
		if err := fuse.Unmount(dir); err != nil {
			return umountCmd("fusermount", "-uz", dir) // Try lazy umount.
		}
		return nil
	}

	// Under Darwin fuse.Umount uses syscall.Umount without syscall.MNT_FORCE flag,
	// so we replace that implementation with diskutil.
	return umountCmd("diskutil", "unmount", "force", dir)
}

func getFuserMountVer() string {
	const fm = "fusermount"

	if runtime.GOOS != "linux" {
		return "unsupported OS " + runtime.GOOS
	}

	if _, err := exec.LookPath(fm); err != nil {
		return "cannot find " + fm + " executable in PATH"
	}

	p, err := exec.Command(fm, "--version").CombinedOutput()
	if err != nil {
		return "unknown " + fm + "version: " + err.Error()
	}

	return strings.TrimSpace(string(p))
}

// Create a map containing all of the key=value mount options to be given to
// the mount helper.
//
// This function is copied from jacobsa/fuse and is meant to provide exact
// command arguments passed to fusermount.
func toMap(c *fuse.MountConfig) (opts map[string]string) {
	isDarwin := runtime.GOOS == "darwin"
	opts = make(map[string]string)

	opts["default_permissions"] = ""
	fsname := c.FSName
	if runtime.GOOS == "linux" && fsname == "" {
		fsname = "some_fuse_file_system"
	}

	// Special file system name?
	if fsname != "" {
		opts["fsname"] = fsname
	}

	// Read only?
	if c.ReadOnly {
		opts["ro"] = ""
	}

	// Handle OS X options.
	if isDarwin {
		if !c.EnableVnodeCaching {
			opts["novncache"] = ""
		}

		if c.VolumeName != "" {
			opts["volname"] = c.VolumeName
		}
	}

	if isDarwin {
		opts["noappledouble"] = ""
	}

	for k, v := range c.Options {
		opts[k] = v
	}

	return
}

func escapeOptionsKey(s string) (res string) {
	res = s
	res = strings.Replace(res, `\`, `\\`, -1)
	res = strings.Replace(res, `,`, `\,`, -1)
	return
}

// Create an options string suitable for passing to the mount helper.
func toOptionsString(c *fuse.MountConfig) string {
	var components []string
	for k, v := range toMap(c) {
		k = escapeOptionsKey(k)

		component := k
		if v != "" {
			component = fmt.Sprintf("%s=%s", k, v)
		}

		components = append(components, component)
	}

	return strings.Join(components, ",")
}
