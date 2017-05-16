package fuse

import (
	"io"
	"os"
	"path/filepath"
	"syscall"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/index/node"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"golang.org/x/net/context"
)

// StatFS sets filesystem metadata.
//
// Required for fuse.FileSystem.
func (fs *Filesystem) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	if fs.Disk == nil {
		return fuse.EINVAL
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
	fs.Index.Tree().DoInodeR(uint64(op.Parent), func(n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child.Exist() {
			op.Entry.Child = fuseops.InodeID(child.Entry.File.Inode)
			op.Entry.Attributes = fs.newAttributes(child.Entry)

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
	fs.Index.Tree().DoInodeR(uint64(op.Inode), func(n *node.Node) {
		if n.Exist() {
			op.Attributes = fs.newAttributes(n.Entry)
			return
		}

		err = fuse.ENOENT
	})

	return
}

// SetInodeAttributes sets specified attributes to file or directory.
func (fs *Filesystem) SetInodeAttributes(_ context.Context, op *fuseops.SetInodeAttributesOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Inode), func(_ node.Guard, n *node.Node) {
		if !n.Exist() {
			err = fuse.ENOENT
			return
		}

		var handleID fuseops.HandleID
		if handleID, err = fs.fileHandles.Open(fs.CacheDir, n); err != nil {
			return
		}

		var fh *FileHandle
		if fh, err = fs.fileHandles.Get(handleID); err != nil {
			return
		}

		op.Attributes = fs.newAttributes(n.Entry)

		// When only access time is being set we are not going to update
		// underlying file because current Entry implementation does not store
		// atime value.
		if op.Atime != nil && (op.Mode == nil && op.Mtime == nil && op.Size == nil) {
			op.Attributes.Atime = *op.Atime
			return
		}

		// Inode size has changed.
		if op.Size != nil {
			if err = fh.File.Truncate(int64(*op.Size)); err != nil {
				fs.fileHandles.Release(handleID)
				err = toErrno(err)
				return
			}
			op.Attributes.Size = *op.Size
		}

		// Inode mode has changed.
		if op.Mode != nil && *op.Mode != 0 {
			if err = fh.File.Chmod(*op.Mode); err != nil {
				fs.fileHandles.Release(handleID)
				err = toErrno(err)
				return
			}
			op.Attributes.Mode = *op.Mode
		}

		// Release file descriptor.
		if err = fs.fileHandles.Release(handleID); err != nil {
			return
		}

		// Set inode modification time.
		if op.Mtime != nil {
			if op.Atime != nil {
				op.Attributes.Atime = *op.Atime
			}

			if op.Mtime != nil {
				op.Attributes.Mtime = *op.Mtime
			}

			if err = os.Chtimes(fh.File.Name(), op.Attributes.Atime, op.Attributes.Mtime); err != nil {
				err = toErrno(err)
				return
			}
		}

		n.Entry.File.CTime = op.Attributes.Mtime.UnixNano()
		n.Entry.File.MTime = n.Entry.File.CTime
		n.Entry.File.Mode = op.Attributes.Mode
		n.Entry.File.Size = int64(op.Attributes.Size)

		n.PromiseUpdate()
		fs.commit(n.Path(), index.ChangeMetaLocal|index.ChangeMetaUpdate)
	})

	return
}

// MkDir creates a new directory inside specified parent directory. It returns
// `fuse.EEXIST` if a file or directory already exists with specified name.
//
// Note: `mkdir` command checks if directory exists before calling this method,
// so you won't see the error from here if you're using `mkdir`.
func (fs *Filesystem) MkDir(_ context.Context, op *fuseops.MkDirOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child.Exist() {
			err = fuse.EEXIST
			return
		}

		path := filepath.Join(n.Path(), op.Name)

		// According to fuse specs mode&os.ModeDir can be zero.
		mode := op.Mode | os.ModeDir
		absPath := filepath.Join(fs.CacheDir, path)
		if err = os.Mkdir(absPath, mode); err != nil {
			err = toErrno(err)
			return
		}

		var entry *node.Entry
		if entry, err = node.NewEntryFile(absPath); err != nil {
			_ = os.Remove(absPath)
			err = toErrno(err)
			return
		}

		child := node.NewNodeEntry(op.Name, entry)
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Child = fuseops.InodeID(child.Entry.File.Inode)
		op.Entry.Attributes = fs.newAttributes(entry)

		// Increase reference counter for entry - fuse_reply_entry.
		incCountNoRoot(child)

		fs.commit(child.Path(), index.ChangeMetaAdd|index.ChangeMetaLocal)
	})

	return
}

// CreateFile creates an empty file with specified name and mode. It returns an
// error if specified parent directory doesn't exist or if the created name
// already has the node.
func (fs *Filesystem) CreateFile(_ context.Context, op *fuseops.CreateFileOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		// Provided name should not exist, but on OSX it may due to not atomic
		// calls from kernel.
		if child := n.GetChild(op.Name); child != nil {
			err = fuse.EEXIST
			return
		}

		path := filepath.Join(fs.CacheDir, n.Path(), op.Name)

		var f *os.File
		if f, err = os.Create(path); err != nil {
			err = toErrno(err)
			return
		}

		if err = f.Chmod(op.Mode); err != nil {
			_ = os.Remove(path)
			err = toErrno(err)
			f.Close()
			return
		}

		var info os.FileInfo
		if info, err = f.Stat(); err != nil {
			_ = os.Remove(path)
			err = toErrno(err)
			f.Close()
			return
		}

		// Add new entry to the tree.
		child := node.NewNodeEntry(op.Name, node.NewEntryFileInfo(info))
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Child = fuseops.InodeID(child.Entry.File.Inode)
		op.Entry.Attributes = fs.newAttributes(child.Entry)
		op.Handle = fs.fileHandles.Add(fuseops.InodeID(child.Entry.File.Inode), f, 0)

		// Increase reference counter for entry - fuse_reply_create.
		incCountNoRoot(child)

		// Set created file as written but not commmit any events. They will be
		// sent anyway by filesystem's flush operation.
		fh, err := fs.fileHandles.Get(op.Handle)
		if err != nil {
			// Panic here since we added handle few lines above.
			panic("created file handle not found")
		}
		fh.Write()
	})

	return
}

// Rename changes a file or directory from old name and parent to new name and
// parent.
//
// Note if a new name already exists, we still go ahead and rename it. While
// the old and new entries are the same, we throw out the old one and create
// new entry for it.
func (fs *Filesystem) Rename(ctx context.Context, op *fuseops.RenameOp) (err error) {
	fs.Index.Tree().DoInode2(uint64(op.OldParent), uint64(op.NewParent),
		func(g node.Guard, oldN, newN *node.Node) {
			if err = checkDir(oldN); err != nil {
				return
			}
			if err = checkDir(newN); err != nil {
				return
			}

			oldChild := oldN.GetChild(op.OldName)
			if !oldChild.Exist() {
				err = fuse.ENOENT
				return
			}

			newChild := newN.GetChild(op.NewName)
			if newChild.Exist() {
				if newChild.Entry.File.Mode.IsDir() != oldChild.Entry.File.Mode.IsDir() {
					err = fuse.EINVAL
					return
				}

				if newChild.Entry.File.Mode.IsDir() && newChild.ChildN() != 0 {
					err = fuse.ENOTEMPTY
					return
				}
			}

			var (
				oldPath = filepath.Join(oldN.Path(), op.OldName)
				newPath = filepath.Join(newN.Path(), op.NewName)
			)

			// Move the actual file only if it's present on disk.
			if oldChild.Entry.Virtual.Promise.Exist() {
				oldAbsPath := filepath.Join(fs.CacheDir, oldPath)
				newAbsPath := filepath.Join(fs.CacheDir, newPath)
				if err = os.Rename(oldAbsPath, newAbsPath); err != nil {
					err = toErrno(err)
					return
				}
			}

			replaced, ok := g.MvChild(oldN, op.OldName, newN, op.NewName)
			if !ok {
				// Panic here since we have a check for missing entry few lines
				// above.
				panic("source entry does not exist")
			}

			if replaced != nil {
				// Replaced is an orphan now, we can't have its path.
				replaced.PromiseDel()
				oldChild.PromiseUpdate()
				fs.commit(newPath, index.ChangeMetaLocal|index.ChangeMetaUpdate)
			} else {
				// oldChild node is now under new path.
				oldChild.PromiseAdd()
				fs.commit(newPath, index.ChangeMetaLocal|index.ChangeMetaAdd)
			}

			// Data on old path was removed during move.
			fs.commit(oldPath, index.ChangeMetaLocal|index.ChangeMetaRemove)
		})

	return
}

// RmDir unlinks a directory from its parent. Since it is not possible to have
// hardlinks to directories, the unlinked directory will be deleted by
// ForgetInode method called by fuse after all reference counters are released.
func (fs *Filesystem) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	return fs.Unlink(ctx, &fuseops.UnlinkOp{
		Parent: op.Parent,
		Name:   op.Name,
	})
}

// Unlink removes entry from specified parent directory. It decreases node
// Nlink counter and, when it reaches 0, it marks the node as deleted but not
// remove any data since this should be done in ForgetInode method.
func (fs *Filesystem) Unlink(_ context.Context, op *fuseops.UnlinkOp) (err error) {
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

		// Remove name from the
		if !n.Orphan() || n.Entry.File.Inode == node.RootInodeID {
			var e error
			if child.Entry.File.Mode.IsDir() {
				e = syscall.Rmdir(filepath.Join(fs.CacheDir, child.Path()))
			} else {
				e = syscall.Unlink(filepath.Join(fs.CacheDir, child.Path()))
			}

			if e != nil {
				err = toErrno(e)
				return
			}
		}

		child.PromiseDel()
		if nlink := child.Entry.Virtual.NLinkDec(); nlink <= 0 {
			fs.commit(child.Path(), index.ChangeMetaLocal|index.ChangeMetaRemove)
			g.Repudiate(n, op.Name)
		}
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

		// Clean up tree.
		if n.Orphan() && n.Entry.File.Inode != node.RootInodeID {
			g.RmOrphan(n)
		}
	})

	return
}

// OpenDir opens a directory, ie. indicates operations are to be done on this
// directory. This function only increases directory handle counter. The handle
// itself is not used.
func (fs *Filesystem) OpenDir(_ context.Context, op *fuseops.OpenDirOp) (err error) {
	fs.Index.Tree().DoInodeR(uint64(op.Inode), func(n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		// Create a new directory handle.
		op.Handle = fs.dirHandles.Open(n)
	})

	return
}

// ReadDir reads entries in a specific directory.
func (fs *Filesystem) ReadDir(_ context.Context, op *fuseops.ReadDirOp) (err error) {
	dh, err := fs.dirHandles.Get(op.Handle)
	if err != nil {
		return err
	}

	fs.Index.Tree().DoInodeR(uint64(op.Inode), func(n *node.Node) {
		if op.Offset != dh.Offset() {
			dh.Rewind(op.Offset, n)
		}
	})

	op.BytesRead, err = dh.ReadDir(op.Offset, op.Dst)

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

	fs.Index.Tree().DoInodeR(uint64(dh.InodeID), func(n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		err = fs.dirHandles.Release(op.Handle)
	})

	return err
}

// CreateSymlink creates a symlink to a given target.
func (fs *Filesystem) CreateSymlink(ctx context.Context, op *fuseops.CreateSymlinkOp) (err error) {
	fs.Index.Tree().DoInode(uint64(op.Parent), func(g node.Guard, n *node.Node) {
		if err = checkDir(n); err != nil {
			return
		}

		if child := n.GetChild(op.Name); child != nil {
			err = fuse.EEXIST
			return
		}

		path := filepath.Join(fs.CacheDir, n.Path(), op.Name)

		if err = syscall.Symlink(op.Target, path); err != nil {
			err = toErrno(err)
			return
		}

		var info os.FileInfo
		if info, err = os.Lstat(path); err != nil {
			_ = os.Remove(path)
			err = toErrno(err)
			return
		}

		// Add new entry to the tree.
		child := node.NewNodeEntry(op.Name, node.NewEntryFileInfo(info))
		g.AddChild(n, child)
		child.PromiseAdd()

		op.Entry.Child = fuseops.InodeID(child.Entry.File.Inode)
		op.Entry.Attributes = fs.newAttributes(child.Entry)

		// Increase reference counter for entry - fuse_reply_create.
		incCountNoRoot(child)

		fs.commit(child.Path(), index.ChangeMetaAdd|index.ChangeMetaLocal)
	})

	return
}

// ReadSymlink allows to read symlink's target.
func (fs *Filesystem) ReadSymlink(ctx context.Context, op *fuseops.ReadSymlinkOp) (err error) {
	fs.Index.Tree().DoInodeR(uint64(op.Inode), func(n *node.Node) {
		if !n.Exist() {
			err = fuse.ENOENT
			return
		}

		path := filepath.Join(fs.CacheDir, n.Path())

		var info os.FileInfo
		if info, err = os.Lstat(path); err != nil {
			err = toErrno(err)
			return
		}

		if info.Mode()&os.ModeSymlink == 0 {
			err = fuse.EINVAL
			return
		}

		if op.Target, err = os.Readlink(path); err != nil {
			err = toErrno(err)
			return
		}
	})

	return
}

// OpenFile opens a File, ie. indicates operations are to be done on this file.
func (fs *Filesystem) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) (err error) {
	fs.Index.Tree().DoInodeR(uint64(op.Inode), func(n *node.Node) {
		if !n.Exist() {
			err = fuse.ENOENT
			return
		}

		var h fuseops.HandleID
		if h, err = fs.fileHandles.Open(fs.CacheDir, n); err != nil {
			return
		}

		op.Handle = h
	})

	return nil
}

// ReadFile reads contents of a specified file starting from specified offset.
// It returns `io.EIO` if specified offset is larger than the length of contents
// of the file.
func (fs *Filesystem) ReadFile(_ context.Context, op *fuseops.ReadFileOp) error {
	fh, err := fs.fileHandles.Get(op.Handle)
	if err != nil {
		return err
	}

	if op.BytesRead, err = fh.File.ReadAt(op.Dst, op.Offset); err != nil && err != io.EOF {
		err = toErrno(err)
		return err
	}

	return nil
}

// WriteFile write specified content to specified file at specified offset.
func (fs *Filesystem) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) (err error) {
	fh, err := fs.fileHandles.Get(op.Handle)
	if err != nil {
		return err
	}

	if _, err = fh.File.WriteAt(op.Data, op.Offset); err != nil {
		err = toErrno(err)
		return
	}

	fs.Index.Tree().DoInode(uint64(fh.InodeID), func(_ node.Guard, n *node.Node) {
		if n == nil {
			return
		}

		n.Entry.File.Size = fh.GrowSize(int64(op.Offset) + int64(len(op.Data)))
	})

	// Mark file handle as modified.
	fh.Write()

	return nil
}

// SyncFile ensures that written data was flushed to device. It also notifies
// external mediums about the updates.
func (fs *Filesystem) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	return fs.syncFile(op.Handle)
}

// FlushFile yields file updates on a locally cached file. Unlike SyncFile, this
// function it is not forced to flush pending writes.
func (fs *Filesystem) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	return fs.syncFile(op.Handle)
}

func (fs *Filesystem) syncFile(handleID fuseops.HandleID) error {
	fh, err := fs.fileHandles.Get(handleID)
	if err != nil {
		return err
	}

	err = fh.File.Sync()

	var path string
	if info, e := fh.File.Stat(); e == nil {
		fs.Index.Tree().DoInode(uint64(fh.InodeID), func(_ node.Guard, n *node.Node) {
			if n == nil {
				return
			}

			n.Entry.File = node.NewEntryFileInfo(info).File
			n.PromiseUpdate()
			path = n.Path()
		})
	}

	// We are not going to commit update events when the file was not modified.
	if err == nil && path != "" && fh.IsModified() {
		fs.commit(path, index.ChangeMetaLocal|index.ChangeMetaUpdate)
	}

	return err
}

// ReleaseFileHandle releases file handle. It does not return errors even if it
// fails since this op doesn't affect anything.
func (fs *Filesystem) ReleaseFileHandle(_ context.Context, op *fuseops.ReleaseFileHandleOp) error {
	return fs.fileHandles.Release(op.Handle)
}

// Destroy cleans up filesystem resources.
func (fs *Filesystem) Destroy() {
	fs.fileHandles.Close()
}

// commit sends generated change to cache with the highest priority.
func (fs *Filesystem) commit(rel string, meta index.ChangeMeta) context.Context {
	return fs.Cache.Commit(index.NewChange(rel, index.PriorityHigh, meta))
}

// lazyDownload downloads virtual entries and makes the node non-virtual if the
// operation succeed. Provided node must be non-nil.
func (fs *Filesystem) lazyDownload(ctx context.Context, n *node.Node) (err error) {
	if !n.Entry.Virtual.Promise.Virtual() {
		return nil
	}

	// Remote to local synchronization is needed so mark the change meta as
	// remote add file.
	c := fs.commit(n.Path(), index.ChangeMetaRemote|index.ChangeMetaAdd)
	select {
	case <-c.Done():
		err = ignoreCtxCancel(c.Err())
	case <-ctx.Done():
		err = ignoreCtxCancel(ctx.Err())
	}

	if err != nil {
		return fuse.EIO
	}

	// Unset node virtual promise.
	n.UnsetPromises()

	return nil
}

// attributes creates a new InodeAttributes from a given node entry.
func (fs *Filesystem) newAttributes(entry *node.Entry) fuseops.InodeAttributes {
	mtime := time.Unix(0, entry.File.MTime)
	ctime := time.Unix(0, entry.File.CTime)

	return fuseops.InodeAttributes{
		Size:  uint64(entry.File.Size),
		Nlink: 1,
		Mode:  entry.File.Mode,

		Atime:  mtime,
		Mtime:  mtime,
		Ctime:  ctime,
		Crtime: ctime,

		Uid: uint32(fs.user().Uid),
		Gid: uint32(fs.user().Gid),
	}
}

// checkDir checks if provided node describes a directory.
func checkDir(n *node.Node) error {
	if !n.Exist() {
		return fuse.ENOENT
	}

	if !n.Entry.File.Mode.IsDir() {
		return fuse.ENOTDIR
	}

	return nil
}

// incCountNoRoot increases node reference counter by one but not for root node
// since there are no methods than could increase it.
func incCountNoRoot(n *node.Node) {
	if n.Entry.File.Inode != node.RootInodeID {
		n.Entry.Virtual.CountInc()
	}
}

// decCountNoRoot decreases node reference counter by provided value and returns
// the number of remaining handles.
func decCountNoRoot(n *node.Node, val uint64) int32 {
	if n.Entry.File.Inode != node.RootInodeID {
		return n.Entry.Virtual.CountDec(int32(val))
	}

	// Root node has always ref count set to 1.
	return 1
}
