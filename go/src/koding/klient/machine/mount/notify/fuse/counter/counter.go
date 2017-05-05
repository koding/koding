package counter

import (
	"fmt"
	"os"
	"os/signal"
	"sort"
	"sync"
	"syscall"
	"text/tabwriter"
	"time"

	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

// Wrap wraps provided filesystem with calls counter.
func Wrap(fs fuseutil.FileSystem) fuseutil.FileSystem {
	return newCounterFS(fs)
}

type measurement struct {
	mu sync.Mutex

	count       uint64
	averageTime float64
}

// Do calls `f`, counts its execution time and increases invocation number by 1.
func (m *measurement) Do(f func()) {
	start := time.Now()
	f()
	execution := float64(time.Since(start))

	m.mu.Lock()
	defer m.mu.Unlock()

	m.count++
	m.averageTime = (m.averageTime*float64(m.count-1) + execution) / float64(m.count)
}

// Status returns current measurement status.
func (m *measurement) Status() (uint64, time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()

	return m.count, time.Duration(m.averageTime)
}

// counterFS implements fuseutil.FileSystem. It counts function invocation
// times and the number of their calls.
type counterFS struct {
	fuseutil.NotImplementedFileSystem
	watched fuseutil.FileSystem

	mu      sync.RWMutex
	methods map[string]*measurement
}

// newCounterFS creates ad returns new counterFS instance. It also starts
// listening for SIGTSTP signal and prints current status when the signal is
// trapped. Sending SIGTSTP twice will reset the counters.
func newCounterFS(watched fuseutil.FileSystem) *counterFS {
	cfs := &counterFS{
		watched: watched,
		methods: make(map[string]*measurement),
	}

	go cfs.loop()

	return cfs
}

// StatFS is a part of fuseutil.FileSystem interface.
func (c *counterFS) StatFS(ctx context.Context, op *fuseops.StatFSOp) (err error) {
	c.watch("StatFS", func(watched fuseutil.FileSystem) {
		err = watched.StatFS(ctx, op)
	})
	return
}

// LookUpInode is a part of fuseutil.FileSystem interface.
func (c *counterFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) (err error) {
	c.watch("LookUpInode", func(watched fuseutil.FileSystem) {
		err = watched.LookUpInode(ctx, op)
	})
	return
}

// GetInodeAttributes is a part of fuseutil.FileSystem interface.
func (c *counterFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) (err error) {
	c.watch("GetInodeAttributes", func(watched fuseutil.FileSystem) {
		err = watched.GetInodeAttributes(ctx, op)
	})
	return
}

// SetInodeAttributes is a part of fuseutil.FileSystem interface.
func (c *counterFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) (err error) {
	c.watch("SetInodeAttributes", func(watched fuseutil.FileSystem) {
		err = watched.SetInodeAttributes(ctx, op)
	})
	return
}

// ForgetInode is a part of fuseutil.FileSystem interface.
func (c *counterFS) ForgetInode(ctx context.Context, op *fuseops.ForgetInodeOp) (err error) {
	c.watch("ForgetInode", func(watched fuseutil.FileSystem) {
		err = watched.ForgetInode(ctx, op)
	})
	return
}

// MkDir is a part of fuseutil.FileSystem interface.
func (c *counterFS) MkDir(ctx context.Context, op *fuseops.MkDirOp) (err error) {
	c.watch("MkDir", func(watched fuseutil.FileSystem) {
		err = watched.MkDir(ctx, op)
	})
	return
}

// MkNode is a part of fuseutil.FileSystem interface.
func (c *counterFS) MkNode(ctx context.Context, op *fuseops.MkNodeOp) (err error) {
	c.watch("MkNode", func(watched fuseutil.FileSystem) {
		err = watched.MkNode(ctx, op)
	})
	return
}

// CreateFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) (err error) {
	c.watch("CreateFile", func(watched fuseutil.FileSystem) {
		err = watched.CreateFile(ctx, op)
	})
	return
}

// CreateSymlink is a part of fuseutil.FileSystem interface.
func (c *counterFS) CreateSymlink(ctx context.Context, op *fuseops.CreateSymlinkOp) (err error) {
	c.watch("CreateSymlink", func(watched fuseutil.FileSystem) {
		err = watched.CreateSymlink(ctx, op)
	})
	return
}

// Rename is a part of fuseutil.FileSystem interface.
func (c *counterFS) Rename(ctx context.Context, op *fuseops.RenameOp) (err error) {
	c.watch("Rename", func(watched fuseutil.FileSystem) {
		err = watched.Rename(ctx, op)
	})
	return
}

// RmDir is a part of fuseutil.FileSystem interface.
func (c *counterFS) RmDir(ctx context.Context, op *fuseops.RmDirOp) (err error) {
	c.watch("RmDir", func(watched fuseutil.FileSystem) {
		err = watched.RmDir(ctx, op)
	})
	return
}

// Unlink is a part of fuseutil.FileSystem interface.
func (c *counterFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) (err error) {
	c.watch("Unlink", func(watched fuseutil.FileSystem) {
		err = watched.Unlink(ctx, op)
	})
	return
}

// OpenDir is a part of fuseutil.FileSystem interface.
func (c *counterFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) (err error) {
	c.watch("OpenDir", func(watched fuseutil.FileSystem) {
		err = watched.OpenDir(ctx, op)
	})
	return
}

// ReadDir is a part of fuseutil.FileSystem interface.
func (c *counterFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) (err error) {
	c.watch("ReadDir", func(watched fuseutil.FileSystem) {
		err = watched.ReadDir(ctx, op)
	})
	return
}

// ReleaseDirHandle is a part of fuseutil.FileSystem interface.
func (c *counterFS) ReleaseDirHandle(ctx context.Context, op *fuseops.ReleaseDirHandleOp) (err error) {
	c.watch("ReleaseDirHandle", func(watched fuseutil.FileSystem) {
		err = watched.ReleaseDirHandle(ctx, op)
	})
	return
}

// OpenFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) (err error) {
	c.watch("OpenFile", func(watched fuseutil.FileSystem) {
		err = watched.OpenFile(ctx, op)
	})
	return
}

// ReadFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) (err error) {
	c.watch("ReadFile", func(watched fuseutil.FileSystem) {
		err = watched.ReadFile(ctx, op)
	})
	return
}

// WriteFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) (err error) {
	c.watch("WriteFile", func(watched fuseutil.FileSystem) {
		err = watched.WriteFile(ctx, op)
	})
	return
}

// SyncFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) (err error) {
	c.watch("SyncFile", func(watched fuseutil.FileSystem) {
		err = watched.SyncFile(ctx, op)
	})
	return
}

// FlushFile is a part of fuseutil.FileSystem interface.
func (c *counterFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) (err error) {
	c.watch("FlushFile", func(watched fuseutil.FileSystem) {
		err = watched.FlushFile(ctx, op)
	})
	return
}

// ReleaseFileHandle is a part of fuseutil.FileSystem interface.
func (c *counterFS) ReleaseFileHandle(ctx context.Context, op *fuseops.ReleaseFileHandleOp) (err error) {
	c.watch("ReleaseFileHandle", func(watched fuseutil.FileSystem) {
		err = watched.ReleaseFileHandle(ctx, op)
	})
	return
}

// ReadSymlink is a part of fuseutil.FileSystem interface.
func (c *counterFS) ReadSymlink(ctx context.Context, op *fuseops.ReadSymlinkOp) (err error) {
	c.watch("ReadSymlink", func(watched fuseutil.FileSystem) {
		err = watched.ReadSymlink(ctx, op)
	})
	return
}

// Destroy is a part of fuseutil.FileSystem interface.
func (c *counterFS) Destroy() {
	c.watch("Destroy", func(watched fuseutil.FileSystem) {
		watched.Destroy()
	})
	return
}

func (c *counterFS) watch(name string, f func(watched fuseutil.FileSystem)) {
	c.mu.RLock()
	ms := c.methods[name]
	if ms == nil {
		ms = &measurement{}
		c.methods[name] = ms
	}
	c.mu.RUnlock()

	ms.Do(func() {
		f(c.watched)
	})
}

func (c *counterFS) loop() {
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGTSTP)

	for range ch {
		fmt.Fprintln(os.Stderr, "Printing method execution statuses:")

		w := tabwriter.NewWriter(os.Stderr, 2, 0, 2, ' ', 0)
		fmt.Fprintf(w, "METHOD\tCALLS\tAVERAGE_TIME\tTOTAL_CPU_TIME\n")

		c.mu.Lock()
		names := make([]string, 0, len(c.methods))
		for name := range c.methods {
			names = append(names, name)
		}

		sort.Strings(names)
		for _, name := range names {
			m := c.methods[name]

			count, averageTime := m.Status()
			fmt.Fprintf(w, "%s\t%d\t%v\t%v\n", name, count, averageTime, time.Duration(count)*averageTime)
		}
		c.mu.Unlock()

		w.Flush()

		select {
		case <-ch:
			fmt.Fprintf(os.Stderr, "Reseting timers...")
			c.mu.Lock()
			c.methods = make(map[string]*measurement)
			c.mu.Unlock()
			fmt.Fprintln(os.Stderr, "OK")
		case <-time.After(500 * time.Millisecond):
			fmt.Fprintln(os.Stderr, "Method counter - Done")
		}
	}
}
