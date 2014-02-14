// +build linux

package virt

import (
	"errors"
	"io"
	"os"
	"path"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"code.google.com/p/go.exp/inotify"
)

type VOS struct {
	VM          *VM
	User        *User
	Permissions *Permissions
}

func (vm *VM) OS(user *User) (*VOS, error) {
	permissions := vm.GetPermissions(user)
	if permissions == nil && user.Uid != RootIdOffset {
		return nil, errors.New("Permission denied.")
	}

	return &VOS{vm, user, permissions}, nil
}

func (vos *VOS) IsReadable(info os.FileInfo) bool {
	sysinfo := info.Sys().(*syscall.Stat_t)
	return info.Mode()&0004 != 0 || (info.Mode()&0040 != 0 && int(sysinfo.Gid) == vos.User.Uid) || int(sysinfo.Uid) == vos.User.Uid || vos.User.Uid == RootIdOffset
}

func (vos *VOS) IsWritable(info os.FileInfo) bool {
	sysinfo := info.Sys().(*syscall.Stat_t)
	return info.Mode()&0002 != 0 || (info.Mode()&0020 != 0 && int(sysinfo.Gid) == vos.User.Uid) || int(sysinfo.Uid) == vos.User.Uid || vos.User.Uid == RootIdOffset
}

var suffixRegexp = regexp.MustCompile(`.((_\d+)?)(\.\w*)?$`)

// EnsureNonexistentPath returns a new path if the given path does exist. The
// returned path is to be ensured to be not existent.
func (vos *VOS) EnsureNonexistentPath(path string) (string, error) {
	name := path
	index := 1
	for {
		_, err := vos.Stat(name)
		if err != nil {
			if os.IsNotExist(err) {
				break // does not exist, return it back
			}
			return "", err
		}

		loc := suffixRegexp.FindStringSubmatchIndex(name)
		name = name[:loc[2]] + "_" + strconv.Itoa(index) + name[loc[3]:]
		index++
	}

	return name, nil
}

func (vos *VOS) resolve(name string, followLastSymlink bool) (string, error) {
	tildePrefix := strings.HasPrefix(name, "~/")
	if !path.IsAbs(name) || tildePrefix {
		if tildePrefix {
			name = name[2:]
		}
		name = "/home/" + vos.User.Name + "/" + name
	}

	constructedPath := ""
	segments := strings.Split(path.Clean(name), "/")[1:]
	for i, segment := range segments {
		// sanity check, should all be removed by path.Clean
		if segment == ".." {
			return "", &os.PathError{Op: "path", Path: name, Err: errors.New("error while processing path")}
		}

		fullPath := vos.VM.File("rootfs/" + constructedPath + "/" + segment)
		info, err := os.Lstat(fullPath)
		if err != nil {
			if !os.IsNotExist(err) {
				return "", err
			}
			// no checks needed if file does not exist
		} else {
			// check for symlink
			if info.Mode()&os.ModeSymlink != 0 && (i < len(segments)-1 || followLastSymlink) {
				link, err := os.Readlink(fullPath)
				if err != nil {
					return "", err
				}
				if !path.IsAbs(link) {
					link = constructedPath + "/" + link
				}
				constructedPath, err = vos.resolve(link, true)
				if err != nil {
					return "", err
				}
				continue
			}

			// check permissions
			if !vos.IsReadable(info) {
				return "", &os.PathError{Op: "path", Path: constructedPath + "/" + segment, Err: errors.New("permission denied")}
			}
		}

		constructedPath += "/" + segment
	}

	return constructedPath, nil
}

func (vos *VOS) ensureWritable(name string) error {
	info, err := os.Stat(name)
	if err != nil {
		if os.IsNotExist(err) {
			dir, _ := path.Split(name)
			return vos.ensureWritable(dir[:len(dir)-1])
		}
		return err
	}

	if !vos.IsWritable(info) {
		return &os.PathError{Op: "path", Path: name, Err: errors.New("permission denied")}
	}
	return nil
}

func (vos *VOS) inVosContext(name string, writeAccess, followLastSymlink bool, f func(name string) error) error {
	vmRoot := vos.VM.File("rootfs")
	vmPath, err := vos.resolve(name, followLastSymlink)
	if err == nil && writeAccess {
		err = vos.ensureWritable(vmRoot + vmPath)
	}
	if err == nil {
		err = f(vmRoot + vmPath)
	}
	if linkErr, ok := err.(*os.LinkError); ok {
		linkErr.Old = strings.Replace(linkErr.Old, vmRoot, "", 1)
		linkErr.New = strings.Replace(linkErr.New, vmRoot, "", 1)
	}
	if pathErr, ok := err.(*os.PathError); ok {
		pathErr.Path = strings.Replace(pathErr.Path, vmRoot, "", 1)
	}
	return err
}

func (vos *VOS) Chmod(name string, mode os.FileMode) error {
	return vos.inVosContext(name, true, true, func(resolved string) error {
		return os.Chmod(resolved, mode)
	})
}

func (vos *VOS) Chown(name string, uid, gid int) error {
	return vos.inVosContext(name, true, true, func(resolved string) error {
		return os.Lchown(resolved, uid, gid)
	})
}

func (vos *VOS) Chtimes(name string, atime time.Time, mtime time.Time) error {
	return vos.inVosContext(name, true, true, func(resolved string) error {
		return os.Chtimes(resolved, atime, mtime)
	})
}

func (vos *VOS) Create(name string) (file *os.File, err error) {
	return vos.OpenFile(name, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0666)
}

func (vos *VOS) Symlink(oldname, newname string) error {
	return vos.inVosContext(newname, true, false, func(resolved string) error {
		if err := os.Symlink(oldname, resolved); err != nil {
			return err
		}
		return os.Lchown(resolved, vos.User.Uid, vos.User.Uid)
	})
}

// IsFile checks whether the given file is a directory or not.
func (vos *VOS) IsFile(file string) (bool, error) {
	sf, err := vos.Open(file)
	if err != nil {
		return false, err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return false, err
	}

	if fi.IsDir() {
		return false, nil
	}

	return true, nil
}

// Exists checks whether the given file exists or not.
func (vos *VOS) Exists(file string) (bool, error) {
	_, err := vos.Stat(file)
	if err == nil {
		return true, nil // file exist
	}

	if os.IsNotExist(err) {
		return false, nil // file does not exist
	}

	return false, err
}

// CopyFile copies the file from src to dst.
func (vos *VOS) CopyFile(src, dst string) error {
	sf, err := vos.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	if fi.IsDir() {
		return errors.New("src is a directory, please provide a file")
	}

	df, err := vos.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
	if err != nil {
		return err
	}
	defer df.Close()

	if _, err := io.Copy(df, sf); err != nil {
		return err
	}

	return nil
}

func (vos *VOS) Stat(name string) (fi os.FileInfo, err error) {
	err = vos.inVosContext(name, false, true, func(resolved string) error {
		fi, err = os.Lstat(resolved) // resolved has already followed all symlinks
		return err
	})
	return
}

func (vos *VOS) LStat(name string) (fi os.FileInfo, err error) {
	err = vos.inVosContext(name, false, false, func(resolved string) error {
		fi, err = os.Lstat(resolved)
		return err
	})
	return
}

func (vos *VOS) Mkdir(name string, perm os.FileMode) error {
	return vos.inVosContext(name, true, false, func(resolved string) error {
		if err := os.Mkdir(resolved, perm); err != nil {
			return err
		}
		return os.Lchown(resolved, vos.User.Uid, vos.User.Uid)
	})
}

func (vos *VOS) MkdirAll(name string, perm os.FileMode) error {
	_, err := vos.Stat(name)
	if err != nil && !os.IsNotExist(err) {
		return err
	}
	if err == nil {
		return nil
	}

	dir, _ := path.Split(name)
	if dir != "" && dir != "/" {
		if err := vos.MkdirAll(dir[:len(dir)-1], perm); err != nil {
			return err
		}
	}
	if err := vos.Mkdir(name, perm); err != nil {
		return err
	}

	return nil
}

func (vos *VOS) Open(name string) (file *os.File, err error) {
	return vos.OpenFile(name, os.O_RDONLY, 0)
}

func (vos *VOS) OpenFile(name string, flag int, perm os.FileMode) (file *os.File, err error) {
	err = vos.inVosContext(name, flag&(os.O_WRONLY|os.O_RDWR|os.O_APPEND|os.O_CREATE|os.O_TRUNC) != 0, true, func(resolved string) error {
		file, err = os.OpenFile(resolved, flag, perm)
		if err != nil {
			return err
		}
		if flag&os.O_CREATE != 0 {
			if err := file.Chown(vos.User.Uid, vos.User.Uid); err != nil {
				file.Close()
				return err
			}
		}
		return nil
	})
	return
}

func (vos *VOS) Readlink(name string) (linkname string, err error) {
	err = vos.inVosContext(name, false, false, func(resolved string) error {
		linkname, err = os.Readlink(resolved)
		return err
	})
	return
}

func (vos *VOS) Remove(name string) error {
	return vos.inVosContext(name, true, false, func(resolved string) error {
		return os.Remove(resolved)
	})
}

func (vos *VOS) RemoveAll(name string) error {
	fi, err := vos.LStat(name)
	if err != nil {
		return err
	}

	if fi.IsDir() {
		dir, err := vos.Open(name)
		if err != nil {
			return err
		}
		defer dir.Close()

		entries, err := dir.Readdirnames(0)
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := vos.RemoveAll(name + "/" + entry); err != nil {
				return err
			}
		}
	}

	return vos.Remove(name)
}

func (vos *VOS) Rename(oldname, newname string) error {
	return vos.inVosContext(oldname, true, false, func(oldnameResolved string) error {
		return vos.inVosContext(newname, true, false, func(newnameResolved string) error {
			return os.Rename(oldnameResolved, newnameResolved)
		})
	})
}

type Watch struct {
	watchSubdirectories bool
	callback            func(*inotify.Event, os.FileInfo)
	root                string
	paths               []string
}

var watcher *inotify.Watcher
var watchMap = make(map[string][]*Watch)
var watchMutex sync.Mutex
var WatchErrors <-chan error

func init() {
	var err error
	watcher, err = inotify.NewWatcher()
	if err != nil {
		panic(err)
	}
	WatchErrors = watcher.Error

	go func() {
		for ev := range watcher.Event {
			func() {
				watchMutex.Lock()
				defer watchMutex.Unlock()

				if ev.Mask&inotify.IN_DELETE_SELF != 0 {
					for _, w := range watchMap[ev.Name] {
						for i, p := range w.paths {
							if p == ev.Name {
								w.paths[i] = w.paths[len(w.paths)-1]
								w.paths = w.paths[:len(w.paths)-1]
								break
							}
						}
					}
					delete(watchMap, ev.Name)
					return
				}

				info, err := os.Lstat(ev.Name)
				if err != nil && !os.IsNotExist(err) {
					watcher.Error <- err
					return
				}

				for _, w := range watchMap[path.Dir(ev.Name)] {
					w.callback(&inotify.Event{Name: strings.Replace(ev.Name, w.root, "", 1), Mask: ev.Mask, Cookie: ev.Cookie}, info)
					if (ev.Mask&(inotify.IN_CREATE|inotify.IN_MOVED_TO)) != 0 && info != nil && info.Mode().IsDir() && w.watchSubdirectories {
						addPathToWatch(w, ev.Name)
					}
				}
			}()
		}
	}()
}

func (vos *VOS) WatchDirectory(name string, watchSubdirectories bool, callback func(*inotify.Event, os.FileInfo)) (*Watch, error) {
	w := &Watch{
		watchSubdirectories: watchSubdirectories,
		callback:            callback,
		root:                vos.VM.File("rootfs"),
		paths:               nil,
	}
	err := vos.inVosContext(name, false, true, func(resolved string) error {
		watchMutex.Lock()
		defer watchMutex.Unlock()
		return addPathToWatch(w, resolved)
	})
	if err != nil {
		w.Close()
		return nil, err
	}
	return w, nil
}

// must be called with locked watchMutex
func addPathToWatch(w *Watch, resolved string) error {
	if len(w.paths) >= 100 {
		return errors.New("Too many subdirectories to watch.")
	}

	err := watcher.AddWatch(resolved, inotify.IN_CREATE|inotify.IN_DELETE|inotify.IN_MOVE|inotify.IN_ATTRIB|inotify.IN_DELETE_SELF)
	if err != nil {
		return err
	}
	w.paths = append(w.paths, resolved)
	watchMap[resolved] = append(watchMap[resolved], w)

	if w.watchSubdirectories {
		dir, err := os.Open(resolved)
		if err != nil {
			return err
		}
		defer dir.Close()

		infos, err := dir.Readdir(0)
		if err != nil {
			return err
		}

		for _, info := range infos {
			if info.Mode().IsDir() && !strings.HasPrefix(info.Name(), ".") {
				if err := addPathToWatch(w, resolved+"/"+info.Name()); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

func (w *Watch) Close() error {
	watchMutex.Lock()
	defer watchMutex.Unlock()

	for _, path := range w.paths {
		watches := watchMap[path]
		for i, entry := range watches {
			if entry == w {
				watches[i] = watches[len(watches)-1]
				watches = watches[:len(watches)-1]
				break
			}
		}
		if len(watches) == 0 {
			delete(watchMap, path)
			return watcher.RemoveWatch(path)
		}
		watchMap[path] = watches
	}

	return nil
}
