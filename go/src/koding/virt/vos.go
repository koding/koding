package virt

import (
	"exp/inotify"
	"fmt"
	"os"
	"path"
	"strings"
	"syscall"
	"time"
)

type VOS struct {
	vm   *VM
	user *User
}

func (vm *VM) OS(user *User) *VOS {
	return &VOS{vm, user}
}

func (vos *VOS) resolve(name string) (string, error) {
	if !path.IsAbs(name) {
		name = "/home/" + vos.user.Name + "/" + name
	}
	constructedPath := ""
	for _, segment := range strings.Split(path.Clean(name), "/")[1:] {
		// sanity check, should all be removed by path.Clean
		if segment == ".." {
			return "", fmt.Errorf("Error while processing path")
		}

		fullPath := vos.vm.File("rootfs/" + constructedPath + "/" + segment)
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
			readable := info.Mode()&0004 != 0 || (info.Mode()&0040 != 0 && int(sysinfo.Gid) == vos.user.Uid) || (info.Mode()&0400 != 0 && int(sysinfo.Uid) == vos.user.Uid)
			if !readable {
				return "", fmt.Errorf("Permission denied: %s/%s", constructedPath, segment)
			}
		}

		constructedPath += "/" + segment
	}
	return constructedPath, nil
}

func (vos *VOS) inVosContext(name string, f func(name string) error) error {
	vmRoot := vos.vm.File("rootfs")
	vmPath, err := vos.resolve(name)
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
	return vos.inVosContext(name, func(resolved string) error {
		return os.Chmod(resolved, mode)
	})
}

func (vos *VOS) Chown(name string, uid, gid int) error {
	return vos.inVosContext(name, func(resolved string) error {
		return os.Chown(resolved, uid, gid)
	})
}

func (vos *VOS) Chtimes(name string, atime time.Time, mtime time.Time) error {
	return vos.inVosContext(name, func(resolved string) error {
		return os.Chtimes(resolved, atime, mtime)
	})
}

func (vos *VOS) Create(name string) (file *os.File, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		file, err = os.Create(resolved)
		if err != nil {
			return err
		}
		if err := file.Chown(vos.user.Uid, vos.user.Uid); err != nil {
			file.Close()
			return err
		}
		return nil
	})
	return
}

func (vos *VOS) Symlink(oldname, newname string) error {
	return vos.inVosContext(oldname, func(resolved string) error {
		if err := os.Symlink(resolved, newname); err != nil {
			return err
		}
		return os.Chown(resolved, vos.user.Uid, vos.user.Uid)
	})
}

func (vos *VOS) Lstat(name string) (fi os.FileInfo, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		fi, err = os.Lstat(resolved)
		return err
	})
	return
}

func (vos *VOS) Mkdir(name string, perm os.FileMode) error {
	return vos.inVosContext(name, func(resolved string) error {
		if err := os.Mkdir(resolved, perm); err != nil {
			return err
		}
		return os.Chown(resolved, vos.user.Uid, vos.user.Uid)
	})
}

func (vos *VOS) Open(name string) (file *os.File, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		file, err = os.Open(resolved)
		return err
	})
	return
}

func (vos *VOS) OpenFile(name string, flag int, perm os.FileMode) (file *os.File, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		file, err = os.OpenFile(resolved, flag, perm)
		if err != nil {
			return err
		}
		if flag&os.O_CREATE != 0 {
			if err := file.Chown(vos.user.Uid, vos.user.Uid); err != nil {
				file.Close()
				return err
			}
		}
		return nil
	})
	return
}

func (vos *VOS) Readlink(name string) (linkname string, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		linkname, err = os.Readlink(resolved)
		return err
	})
	return
}

func (vos *VOS) Rename(oldname, newname string) error {
	return vos.inVosContext(oldname, func(oldnameResolved string) error {
		return vos.inVosContext(newname, func(newnameResolved string) error {
			return os.Rename(oldnameResolved, newnameResolved)
		})
	})
}

func (vos *VOS) AddWatch(w *inotify.Watcher, name string, flags uint32) (watchedPath string, err error) {
	err = vos.inVosContext(name, func(resolved string) error {
		watchedPath = resolved
		return w.AddWatch(resolved, flags)
	})
	return
}
