package fuseklient

import (
	"fmt"
	"math/rand"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
	"golang.org/x/net/trace"
)

type TraceFS struct {
	Id string
	*KodingNetworkFS
}

func NewTraceFS(k *KodingNetworkFS) *TraceFS {
	return &TraceFS{
		Id:              randSeq(6),
		KodingNetworkFS: k,
	}
}

func (t *TraceFS) Mount() (*fuse.MountedFileSystem, error) {
	r, _ := t.newTrace(nil, "Mount", "Path=%s", t.MountPath)
	defer r.Finish()

	server := fuseutil.NewFileSystemServer(t)
	fs, err := fuse.Mount(t.MountPath, server, t.MountConfig)
	if err != nil {
		r.LazyPrintf("KodingNetworkFS#Mount: err '%s'", err)
		r.SetError()

		return nil, err
	}

	return fs, nil
}

func (t *TraceFS) Unmount() error {
	r, _ := t.newTrace(nil, "Unmount", "Path=%s", t.MountPath)
	defer r.Finish()

	if err := t.KodingNetworkFS.Unmount(); err != nil {
		r.LazyPrintf("KodingNetworkFS#Unmount err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	r, ctx := t.newTrace(ctx, "GetInodeAttributes", "ID=%d", op.Inode)
	defer r.Finish()

	if err := t.KodingNetworkFS.GetInodeAttributes(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#GetInodeAttributes err:%s", err)
		r.SetError()

		return err
	}

	logAttrs(r, op.Attributes)

	return nil
}

func (t *TraceFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	r, ctx := t.newTrace(ctx, "LookUpInode", "ParentID=%d Name=%s", op.Parent, op.Name)
	defer r.Finish()

	if err := t.KodingNetworkFS.LookUpInode(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#LookUpInode err:%s", err)
		r.SetError()

		return err
	}

	logAttrs(r, op.Entry.Attributes)

	return nil
}

func (t *TraceFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) error {
	r, ctx := t.newTrace(ctx, "OpenDir", "ID=%d, HandleID=%d", op.Inode, op.Handle)
	defer r.Finish()

	if err := t.KodingNetworkFS.OpenDir(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#OpenDir err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	r, ctx := t.newTrace(ctx, "ReadDir", "ID=%d Offset=%d", op.Inode, op.Offset)
	defer r.Finish()

	if err := t.KodingNetworkFS.ReadDir(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#ReadDir err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf("res: read=%d bytes", op.BytesRead)

	return nil
}

func (t *TraceFS) MkDir(ctx context.Context, op *fuseops.MkDirOp) error {
	r, ctx := t.newTrace(ctx, "MkDir", "ParentID=%d Name=%s", op.Parent, op.Name)
	defer r.Finish()

	if err := t.KodingNetworkFS.MkDir(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#MkDir err:%s", err)
		r.SetError()

		return err
	}

	logAttrs(r, op.Entry.Attributes)

	return nil
}

func (t *TraceFS) Rename(ctx context.Context, op *fuseops.RenameOp) error {
	r, ctx := t.newTrace(ctx, "Rename", "Old=%v,%s New=%v,%s", op.OldParent, op.OldName, op.NewParent, op.NewName)
	defer r.Finish()

	if err := t.KodingNetworkFS.Rename(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#Rename err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) RmDir(ctx context.Context, op *fuseops.RmDirOp) error {
	r, ctx := t.newTrace(ctx, "RmDir", "Parent=%d Name=%s", op.Parent, op.Name)
	defer r.Finish()

	if err := t.KodingNetworkFS.RmDir(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#RmDir err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) error {
	r, ctx := t.newTrace(ctx, "OpenFile", "ID=%v", op.Inode)
	defer r.Finish()

	if err := t.KodingNetworkFS.OpenFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#OpenFile err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf("res: handle=%d", op.Handle)

	return nil
}

func (t *TraceFS) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) error {
	r, ctx := t.newTrace(ctx, "ReadFile", "ID=%v Offset=%v", op.Inode, op.Offset)
	defer r.Finish()

	if err := t.KodingNetworkFS.ReadFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#ReadFile err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf("res: read=%d bytes at offset=%d", op.BytesRead, op.Offset)

	return nil
}

func (t *TraceFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) error {
	r, ctx := t.newTrace(ctx, "WriteFile", "ID=%v DataLen=%v Offset=%v", op.Inode, len(op.Data), op.Offset)
	defer r.Finish()

	if err := t.KodingNetworkFS.WriteFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#WriteFile err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf("result: wrote=%d bytes at offset=%d", len(op.Data), op.Offset)

	return nil
}

func (t *TraceFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) error {
	r, ctx := t.newTrace(ctx, "CreateFile", "Parent=%v Name=%s Mode=%s", op.Parent, op.Name, op.Mode)
	defer r.Finish()

	if err := t.KodingNetworkFS.CreateFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#CreateFile err:%s", err)
		r.SetError()

		return err
	}

	logAttrs(r, op.Entry.Attributes)

	return nil
}

func (t *TraceFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) error {
	r, ctx := t.newTrace(ctx, "SetInodeAttributes", "ID=%v Size=%d Mode=%s", op.Inode, op.Size, op.Mode)
	defer r.Finish()

	if err := t.KodingNetworkFS.SetInodeAttributes(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#SetInodeAttributes err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf(
		"res: size=%d, mode=%s atime=%s mtime=%s", op.Size, op.Mode, op.Atime, op.Mtime,
	)

	return nil
}

func (t *TraceFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) error {
	r, ctx := t.newTrace(ctx, "FlushFile", "ID=%d Handle=%d", op.Inode, op.Handle)
	defer r.Finish()

	if err := t.KodingNetworkFS.FlushFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#FlushFile err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) error {
	r, ctx := t.newTrace(ctx, "SyncFile", "ID=%v Handle=%v", op.Inode, op.Handle)
	defer r.Finish()

	if err := t.KodingNetworkFS.SyncFile(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#SyncFile err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) error {
	r, ctx := t.newTrace(ctx, "Unlink", "Parent=%v Name=%s", op.Parent, op.Name)
	defer r.Finish()

	if err := t.KodingNetworkFS.Unlink(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#Unlink err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

func (t *TraceFS) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	r, ctx := t.newTrace(ctx, "StatFS", "")
	defer r.Finish()

	if err := t.KodingNetworkFS.StatFS(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#StatFS err:%s", err)
		r.SetError()

		return err
	}

	r.LazyPrintf(
		"res: blockSize=%d blocks=%d blocksFree=%d, blocksAvailable=%d",
		op.BlockSize, op.Blocks, op.BlocksFree, op.BlocksAvailable,
	)

	return nil
}

func (t *TraceFS) ReleaseFileHandle(ctx context.Context, op *fuseops.ReleaseFileHandleOp) error {
	r, ctx := t.newTrace(ctx, "ReleaseFileHandle", "Handle=%v", op.Handle)
	defer r.Finish()

	if err := t.KodingNetworkFS.ReleaseFileHandle(ctx, op); err != nil {
		r.LazyPrintf("KodingNetworkFS#ReleaseFileHandle err:%s", err)
		r.SetError()

		return err
	}

	return nil
}

///// Helpers

///// trace helpers

func (t *TraceFS) newTrace(ctx context.Context, name, ft string, args ...interface{}) (trace.Trace, context.Context) {
	argsFmt := fmt.Sprintf(ft, args...)
	v := fmt.Sprintf("%s-%s %s", t.Id, t.MountConfig.FSName, argsFmt)

	if ctx == nil {
		ctx = context.TODO()
	}

	r := trace.New(name, v)
	ctx = trace.NewContext(ctx, r)

	return r, ctx
}

func logAttrs(r trace.Trace, a fuseops.InodeAttributes) {
	r.LazyPrintf(
		"res: size=%d, mode=%s atime=%s mtime=%s", a.Size, a.Mode, a.Atime, a.Mtime,
	)
}

// random string generator

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func randSeq(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
