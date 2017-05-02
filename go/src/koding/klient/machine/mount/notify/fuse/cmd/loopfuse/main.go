// +build !windows

package main

import (
	"context"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/machine/mount/notify"
	"koding/klient/machine/mount/notify/fuse"
	"koding/klient/machine/mount/notify/fuse/counter"
	"koding/klient/machine/mount/notify/fuse/fusetest"
)

const sep = string(os.PathSeparator)

var (
	verbose = flag.Bool("v", false, "Turn on verbose logging.")
	tmp     = flag.String("tmp", "", "Existing cache directory to use.")
	change  = flag.Bool("change", false, "Print produced FS changes.")
	null    = flag.Bool("null", false, "Ignore all changes and report them as completed")
	count   = flag.Bool("count", false, "Count fuse calls. Use Ctrl+Z to display counters.")
)

const usage = `usage: loopfuse [-v] [-tmp] [-change] [-null] <src> <dst>

Flags

	-v      Turns on verbose logging.
	-tmp    Existing cache directory to use.
	-change Print produced FS changes.
	-null   Ignore all changes and report them as completed.
	-count  Count fuse calls. Use Ctrl+Z to display counters.

Arguments

	src  Source directory.
	dst  Destination directory.
`

func die(v ...interface{}) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}

func main() {
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()
	flag.Parse()

	if flag.NArg() != 2 {
		die(usage)
	}

	src, dst := flag.Arg(0), flag.Arg(1)

	if !filepath.IsAbs(src) {
		var err error
		if src, err = filepath.Abs(src); err != nil {
			die(err)
		}
	}

	if _, err := os.Stat(dst); err != nil {
		die(err)
	}

	if _, err := os.Stat(src); err != nil {
		die(err)
	}

	if *tmp == "" {
		var err error
		*tmp, err = ioutil.TempDir("", "loopfuse")
		if err != nil {
			die(err)
		}
	}

	if !strings.HasSuffix(*tmp, sep) {
		*tmp = *tmp + sep
	}

	log.Printf("using cache directory: %s", *tmp)
	log.Printf("building index for: %s", src)

	bc, err := fusetest.NewBindCache(src, *tmp)
	if err != nil {
		die(err)
	}

	var cache notify.Cache = bc
	if *null {
		log.Printf("using null cache")
		cache = nullCache{}
	}
	if *change {
		log.Printf("print cache commits")
		cache = &printCache{sub: cache}
	}

	fmt.Println(bc.Index().DebugString())

	opts := &fuse.Options{
		Cache:    cache,
		CacheDir: *tmp,
		Index:    bc.Index(),
		Mount:    filepath.Base(dst),
		MountDir: dst,
		Debug:    *verbose,
		Disk:     block(dst),
	}

	log.Printf("mounting filesystem: %s", dst)

	var fs *fuse.Filesystem
	if *count {
		log.Printf("filesystem's method call counter is enabled")
		fs, err = fuse.NewFilesystem(opts, counter.Wrap)
	} else {
		fs, err = fuse.NewFilesystem(opts)
	}
	if err != nil {
		die(err)
	}

	ch := make(chan os.Signal, 1)

	signal.Notify(ch, syscall.SIGQUIT)

	go func() {
		for range ch {
			fmt.Print(fs.Index.DebugString())
		}
	}()

	runtime.KeepAlive(fs)

	log.Printf("all done")

	select {}
}

func block(path string) *fs.DiskInfo {
	stfs := syscall.Statfs_t{}

	if err := syscall.Statfs(path, &stfs); err != nil {
		die(err)
	}

	di := &fs.DiskInfo{
		BlockSize:   uint32(stfs.Bsize),
		BlocksTotal: stfs.Blocks,
		BlocksFree:  stfs.Bfree,
	}

	di.BlocksUsed = di.BlocksTotal - di.BlocksFree

	return di
}

type printCache struct {
	sub notify.Cache
}

func (pc *printCache) Commit(c *index.Change) context.Context {
	log.Println("Commit:", c)
	return pc.sub.Commit(c)
}

type nullCache struct{}

func (nullCache) Commit(c *index.Change) context.Context {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	return ctx
}
