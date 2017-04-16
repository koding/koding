package fuse

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// StatFS sets filesystem metadata.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	if fs.Disk == nil {
		return fuse.ENOENT
	}

	op.Blocks = fs.Disk.BlocksTotal
	op.BlockSize = fs.Disk.BlockSize
	op.BlocksFree = fs.Disk.BlocksFree
	op.BlocksAvailable = fs.Disk.BlocksTotal - fs.Disk.BlocksUsed
	op.IoSize = uint32(fs.Disk.IOSize)

	return nil
}

// LookUpInode finds entry in context of specific parent directory and sets
// its attributes. It assumes parent directory has already been seen.
func (fs *Filesystem) LookUpInode(_ context.Context, op *fuseops.LookUpInodeOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(_ node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child.Exist() {
			op.Entry.Child = fuseops.InodeID(child.Entry.Virtual.Inode)
			op.Entry.Attributes = fs.attr(child.Entry)

			// Increase reference counter for entry - fuse_reply_entry.
			incCountNoRoot(child)
			return
		}

		err = fuse.ENOENT
	})

	return err
}

// GetInodeAttributes gets attributes of a node pointed by provided inode ID.
func (fs *Filesystem) GetInodeAttributes(_ context.Context, op *fuseops.GetInodeAttributesOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n.Exist() {
			op.Attributes = fs.attr(n.Entry)
			return
		}

		err = fuse.ENOENT
	})

	return
}

// SetInodeAttributes sets specified attributes to file or directory.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) (err error) {
	var rel string
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n == nil || !n.Entry.Virtual.Promise.Exist() {
			err = fuse.ENOENT
			return
		}

		rel := n.Path()

		var f *os.File
		if f, err = fs.openFile(ctx, rel, n.Entry.File.Mode); err != nil {
			return
		}

		op.Attributes = fs.attr(n.Entry)
		if op.Size != nil {
			if err = f.Truncate(int64(*op.Size)); err != nil {
				f.Close()
				return
			}
			op.Attributes.Size = *op.Size
		}

		if op.Mode != nil && *op.Mode != 0 {
			if err = f.Chmod(*op.Mode); err != nil {
				f.Close()
				return
			}
			op.Attributes.Mode = *op.Mode
		}

		if err = f.Close(); err != nil {
			return
		}

		if op.Atime != nil || op.Mtime != nil {
			if op.Atime != nil {
				op.Attributes.Atime = *op.Atime
			}

			if op.Mtime != nil {
				op.Attributes.Mtime = *op.Mtime
			}

			if err = os.Chtimes(f.Name(), op.Attributes.Atime, op.Attributes.Mtime); err != nil {
				return
			}
		}

		n.Entry.File.MTime = op.Attributes.Mtime.UnixNano()
		n.Entry.File.Mode = op.Attributes.Mode
		n.Entry.File.Size = int64(op.Attributes.Size)
	})

	if err == nil {
		fs.commit(rel, index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return
}

// MkDir creates a new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
func (fs *Filesystem) MkDir(ctx context.Context, op *fuseops.MkDirOp) (err error) {
	var path string
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child.Exist() {
			err = fuse.EEXIST
			return
		}

		path = filepath.Join(n.Path(), op.Name)

		// According to fuse specs mode&os.ModeDir can be zero.
		mode := op.Mode | os.ModeDir
		absPath := filepath.Join(fs.CacheDir, path)
		if err = os.MkdirAll(absPath, mode); err != nil {
			err = toErrno(err)
			return
		}

		entry, err := node.NewEntryFile(absPath)
		if err != nil {
			err = toErrno(err)
			return
		}

		child := node.NewNodeEntry(op.Name, entry)
		g.AddChild(n, child)
		child.PromiseAdd()

		// Increase reference counter for entry - fuse_reply_entry.
		incCountNoRoot(child)

		op.Entry.Child = fuseops.InodeID(child.Entry.Virtual.Inode)
		op.Entry.Attributes = fs.newAttr(mode)
	})

	if err == nil {
		fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)
	}

	return
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist. but not if file already
// exists.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) (err error) {
	var path string
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child != nil && child.Entry.Virtual.Promise.Exist() {
			err = fuse.EEXIST
			return
		}

		path = filepath.Join(n.Path(), op.Name)
		abs := filepath.Join(fs.CacheDir, path)
		if err = os.MkdirAll(filepath.Dir(abs), 0755); err != nil {
			return
		}

		var f *os.File
		if f, err = os.Create(abs); err != nil {
			return
		}

		_ = f.Chmod(op.Mode)

		child := node.NewNodeEntry(op.Name, node.NewEntry(0, op.Mode))
		child.Entry.Virtual.CountInc()
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Attributes = fs.newAttr(op.Mode)
		op.Handle = fs.addHandle(fuseops.InodeID(child.Entry.Virtual.Inode), f)
	})

	if err == nil {
		fs.commit(path, index.ChangeMetaAdd|index.ChangeMetaLocal)
	}

	return
}

// Rename changes a file or directory from old name and parent to new name and
// parent.
//
// Note if a new name already exists, we still go ahead and rename it. While
// the old and new entries are the same, we throw out the old one and create
// new entry for it.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) Rename(ctx context.Context, op *fuseops.RenameOp) (err error) {
	var oldPath, newPath string
	fs.Index.Tree().DoInode2(uint64(op.OldParent), uint64(op.NewParent),
		func(g node.Guard, oldN, newN *node.Node) {
			if err = checkDir(oldN); err != nil {
				return
			}
			if err = checkDir(newN); err != nil {
				return
			}

			oldChild := oldN.GetChild(op.OldName)
			if oldChild == nil || !oldChild.Entry.Virtual.Promise.Exist() {
				err = fuse.ENOENT
				return
			}

			newChild := newN.GetChild(op.NewName)
			if newChild != nil && newChild.Entry.Virtual.Promise.Exist() {
				if newChild.Entry.File.Mode.IsDir() != oldChild.Entry.File.Mode.IsDir() {
					err = fuse.EINVAL
					return
				}

				if newChild.Entry.File.Mode.IsDir() && newChild.ChildN() != 0 {
					err = fuse.ENOTEMPTY
					return
				}
			}

			oldPath = filepath.Join(oldN.Path(), op.OldName)
			newPath = filepath.Join(newN.Path(), op.NewName)

			if err = fs.move(ctx, oldPath, newPath); err != nil {
				return
			}

			cloned := oldN.Clone()
			cloned.Name = op.NewName
			cloned.Entry.Virtual.Inode = fs.Index.Tree().GenerateInode()

			g.AddChild(newN, cloned)

			oldChild.PromiseDel()
			cloned.PromiseAdd()
		})

	if err == nil {
		fs.commit(oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove)
		fs.commit(newPath, index.ChangeMetaLocal|index.ChangeMetaAdd)
	}

	return
}

// RmDir unlinks a directory from its parent. Since it is not possible to have
// hardlinks to directories, the unlinked directory will be deleted by
// ForgetInode method called by fuse after all reference counters are released.
func (fs *Filesystem) RmDir(ctx context.Context, op *fuseops.RmDirOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		// Allow deleted nodes.
		if n == nil {
			err = fuse.ENOENT
			return
		}

		if !n.Entry.File.Mode.IsDir() {
			err = fuse.ENOTDIR
			return
		}

		child := n.GetChild(op.Name)
		if child == nil {
			err = fuse.ENOENT
			return
		}

		if !child.Entry.File.Mode.IsDir() {
			err = fuse.ENOTDIR
			return
		}

		child.PromiseDel()
		child.Entry.Virtual.NLinkDec()
	})

	return
}

// Unlink removes entry from specified parent directory. It decreases node
// Nlink counter and, when it reaches 0, it marks the node as deleted but not
// remove any data since this should be done in ForgetInode method.
func (fs *Filesystem) Unlink(_ context.Context, op *fuseops.UnlinkOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(_ node.Guard, n *node.Node) {
		// Allow deleted nodes.
		if n == nil {
			err = fuse.ENOENT
			return
		}

		if !n.Entry.File.Mode.IsDir() {
			err = fuse.ENOTDIR
			return
		}

		child := n.GetChild(op.Name)
		if child == nil {
			err = fuse.ENOENT
			return
		}

		child.PromiseDel()
		child.Entry.Virtual.NLinkDec()
	})

	return
}

// ForgetInode decreases Node reference count and if it reaches 0, this method
// will remove isk data from the underlying filesystem as well as the Node
// from tree.
func (fs *Filesystem) ForgetInode(ctx context.Context, op *fuseops.ForgetInodeOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(g node.Guard, n *node.Node) {
		// Nil means that inode was already forgotten.
		if n == nil {
			return
		}

		if count := decCountNoRoot(n, op.N); count > 0 {
			return
		}

		path := n.Path()
		// Try to delete even if the underlying filesystem operation fails.
		defer func() {
			fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaRemove)
		}()

		absPath := filepath.Join(fs.CacheDir, path)
		if err := os.RemoveAll(absPath); os.IsNotExist(err) {
			return
		} else if err != nil {
			err = toErrno(err)
			return
		}

		// Clean up tree.
		if parent := n.Parent(); parent != nil {
			g.RmChild(parent, n.Name)
		}
	})

	return
}

// OpenDir opens a directory, ie. indicates operations are to be done on this
// directory. This function only increases directory handle counter. The handle
// itself is not used.
func (fs *Filesystem) OpenDir(_ context.Context, op *fuseops.OpenDirOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		// Create a new directory handle.
		op.Handle = fs.dirHandles.Open(op.Inode)
	})

	return
}

// ReadDir reads entries in a specific directory.
func (fs *Filesystem) ReadDir(_ context.Context, op *fuseops.ReadDirOp) (err error) {
	var (
		dirents   []fuseutil.Dirent
		dotOffset = op.Offset
	)

	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		parent, shift := n.Parent(), 1
		if parent != nil || fs.mDirParentInode != 0 {
			shift++
		}

		// Add "." directory.
		if dotOffset == 0 {
			dotOffset++
			dirents = append(dirents, fuseutil.Dirent{
				Offset: dotOffset,
				Inode:  fuseops.InodeID(n.Entry.Virtual.Inode),
				Name:   ".",
				Type:   direntType(n.Entry),
			})
		}

		// Add ".." directory.
		if dotOffset == 1 && shift > 1 {
			dotOffset++
			inode := fs.mDirParentInode
			if parent != nil {
				inode = fuseops.InodeID(parent.Entry.Virtual.Inode)
			}

			dirents = append(dirents, fuseutil.Dirent{
				Offset: dotOffset,
				Inode:  inode,
				Name:   "..",
				Type:   fuseutil.DT_Directory,
			})
		}

		offset := int(dotOffset) - shift
		if offset > n.ChildN() {
			err = fuse.EINVAL
			return
		} else if offset == n.ChildN() {
			return
		}

		var i = 1
		n.Children(offset, func(child *node.Node) {
			dirents = append(dirents, fuseutil.Dirent{
				Offset: dotOffset + fuseops.DirOffset(i),
				Inode:  fuseops.InodeID(child.Entry.Virtual.Inode),
				Name:   child.Name,
				Type:   direntType(child.Entry),
			})

			i++
		})
	})

	var n, bytesRead int
	for i := range dirents {
		if n = fuseutil.WriteDirent(op.Dst[bytesRead:], dirents[i]); n == 0 {
			break
		}
		bytesRead += n
	}

	op.BytesRead += bytesRead

	return
}

// ReleaseDirHandle removes a directory under the given handle ID for open ones.
// Since file system doesn't use handles, this function only decreases entry
// reference counter.
func (fs *Filesystem) ReleaseDirHandle(_ context.Context, op *fuseops.ReleaseDirHandleOp) error {
	dh, err := fs.dirHandles.Get(op.Handle)
	if err != nil {
		return err
	}

	fs.Index.Tree().DoInode(uint64(dh.InodeID), func(_ node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if err = fs.dirHandles.Release(op.Handle); err != nil {
			return
		}
	})

	return err
}

// OpenFile opens a File, ie. indicates operations are to be done on this file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) (err error) {
	var h fuseops.HandleID
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if n == nil {
			err = fuse.ENOENT
			return
		}

		_, h, err = fs.open(ctx, n)
	})

	op.KeepPageCache = false
	op.Handle = h

	return nil
}

// ReadFile reads contents of a specified file starting from specified offset.
// It returns `io.EIO` if specified offset is larger than the length of contents
// of the file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	f, _, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	op.BytesRead, err = f.ReadAt(op.Dst, op.Offset)
	if err == io.EOF {
		err = nil // ignore io.EOF errors
	}

	return err
}

// WriteFile write specified contents to specified file at specified offset.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	if _, err = f.WriteAt(trimRightNull(op.Data), op.Offset); err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return nil
}

// SyncFile sends file contents from local to remote.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return err
}

// FlushFile yields file updates on a locally cached file.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	if op.Handle == 0 {
		return nil
	}

	f, nID, err := fs.openHandleInfo(op.Handle)
	if err != nil {
		return err
	}

	err = f.Sync()
	if fi, e := f.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(nID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File.Size = fi.Size()
		})
	}

	if err == nil {
		fs.commit(fs.rel(f.Name()), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return err
}

// ReleaseFileHandle releases file handle. It does not return errors even if it
// fails since this op doesn't affect anything.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) ReleaseFileHandle(_ context.Context, op *fuseops.ReleaseFileHandleOp) error {
	_ = fs.delHandle(op.Handle)
	return nil
}

func (fs *Filesystem) Destroy() {
	fs.mu.Lock()
	for _, f := range fs.handles {
		_ = f.File.Close()
	}
	fs.handles = make(map[fuseops.HandleID]HandleInfo)
	fs.mu.Unlock()
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

// incCountNoRoot increases node reference counter by one but not for root node
// since there are no methods than could increase it.
func incCountNoRoot(n *node.Node) {
	if n.Entry.Virtual.Inode != node.RootInodeID {
		n.Entry.Virtual.CountInc()
	}
}

// decCountNoRoot decreases node reference counter by provided value and returns
// the number of remaining handles.
func decCountNoRoot(n *node.Node, val uint64) int32 {
	if n.Entry.Virtual.Inode != node.RootInodeID {
		return n.Entry.Virtual.CountDec(int32(val))
	}

	// Root node has always ref count set to 1.
	return 1
}
