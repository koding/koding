package virt

import (
	"errors"
	"exp/inotify"
	"os"
	"path"
	"strings"
	"syscall"
	"time"
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

func (vos *VOS) resolve(name string) (string, error) {
	tildePrefix := strings.HasPrefix(name, "~/")
	if !path.IsAbs(name) || tildePrefix {
		if tildePrefix {
			name = name[2:]
		}
		name = "/home/" + vos.User.Name + "/" + name
	}

	constructedPath := ""
	for _, segment := range strings.Split(path.Clean(name), "/")[1:] {
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
			if info.Mode()&os.ModeSymlink != 0 {
				link, err := os.Readlink(fullPath)
				if err != nil {
					return "", err
				}
				if !path.IsAbs(link) {
					link = constructedPath + "/" + link
				}
				constructedPath, err = vos.resolve(link)
				if err != nil {
					return "", err
				}
				continue
			}

			// check permissions
			sysinfo := info.Sys().(*syscall.Stat_t)
			readable := info.Mode()&0004 != 0 || (info.Mode()&0040 != 0 && int(sysinfo.Gid) == vos.User.Uid) || (info.Mode()&0400 != 0 && int(sysinfo.Uid) == vos.User.Uid) || vos.User.Uid == RootIdOffset
			if !readable {
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

	sysinfo := info.Sys().(*syscall.Stat_t)
	writable := info.Mode()&0002 != 0 || (info.Mode()&0020 != 0 && int(sysinfo.Gid) == vos.User.Uid) || (info.Mode()&0200 != 0 && int(sysinfo.Uid) == vos.User.Uid) || vos.User.Uid == RootIdOffset
	if !writable {
		return &os.PathError{Op: "path", Path: name, Err: errors.New("permission denied")}
	}
	return nil
}

func (vos *VOS) inVosContext(name string, writeAccess bool, f func(name string) error) error {
	vmRoot := vos.VM.File("rootfs")
	vmPath, err := vos.resolve(name)
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
	return vos.inVosContext(name, true, func(resolved string) error {
		return os.Chmod(resolved, mode)
	})
}

func (vos *VOS) Chown(name string, uid, gid int) error {
	return vos.inVosContext(name, true, func(resolved string) error {
		return os.Lchown(resolved, uid, gid)
	})
}

func (vos *VOS) Chtimes(name string, atime time.Time, mtime time.Time) error {
	return vos.inVosContext(name, true, func(resolved string) error {
		return os.Chtimes(resolved, atime, mtime)
	})
}

func (vos *VOS) Create(name string) (file *os.File, err error) {
	return vos.OpenFile(name, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0666)
}

func (vos *VOS) Symlink(oldname, newname string) error {
	return vos.inVosContext(newname, true, func(resolved string) error {
		if err := os.Symlink(oldname, resolved); err != nil {
			return err
		}
		return os.Lchown(resolved, vos.User.Uid, vos.User.Uid)
	})
}

func (vos *VOS) Stat(name string) (fi os.FileInfo, err error) {
	err = vos.inVosContext(name, false, func(resolved string) error {
		fi, err = os.Lstat(resolved) // resolved has already followed all symlinks
		return err
	})
	return
}

func (vos *VOS) Mkdir(name string, perm os.FileMode) error {
	return vos.inVosContext(name, true, func(resolved string) error {
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
	if dir != "" {
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
	err = vos.inVosContext(name, flag&(os.O_WRONLY|os.O_RDWR|os.O_APPEND|os.O_CREATE|os.O_TRUNC) != 0, func(resolved string) error {
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
	err = vos.inVosContext(name, false, func(resolved string) error {
		linkname, err = os.Readlink(resolved)
		return err
	})
	return
}

func (vos *VOS) Remove(name string) error {
	return vos.inVosContext(name, true, func(resolved string) error {
		return os.Remove(resolved)
	})
}

func (vos *VOS) RemoveAll(name string) error {
	fi, err := vos.Stat(name)
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
	return vos.inVosContext(oldname, true, func(oldnameResolved string) error {
		return vos.inVosContext(newname, true, func(newnameResolved string) error {
			return os.Rename(oldnameResolved, newnameResolved)
		})
	})
}

func (vos *VOS) AddWatch(w *inotify.Watcher, name string, flags uint32) (watchedPath string, err error) {
	err = vos.inVosContext(name, false, func(resolved string) error {
		watchedPath = resolved
		return w.AddWatch(resolved, flags)
	})
	return
}
