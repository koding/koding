// +build !windows

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"syscall"

	"koding/klient/fs"
	"koding/klient/machine/mount/notify/fuse"
	"koding/klient/machine/mount/notify/fuse/fusetest"
)

var (
	verbose = flag.Bool("v", false, "Turn on verbose logging.")
	tmp     = flag.String("tmp", "", "Existing cache directory to use.")
)

const usage = `usage: loopfuse [-v] [-tmp]  <src> <dst>

Flags

	-v    Turns on verbose logging.
	-tmp  Existing cache directory to use.

Arguments

	src  Source directory.
	dst  Destination directory.
`

func die(v ...interface{}) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}

func logf(format string, args ...interface{}) {
	if *verbose {
		log.Printf(format, args...)
	}
}

func main() {
	flag.Parse()

	if flag.NArg() != 2 {
		die(usage)
	}

	src, dst := flag.Arg(0), flag.Arg(1)

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

	logf("using cache directory: %s", *tmp)
	logf("building index for: %q", src)

	bc, err := fusetest.NewBindCache(src, *tmp)
	if err != nil {
		die(err)
	}

	opts := &fuse.Opts{
		Cache:    bc,
		CacheDir: *tmp,
		Remote:   bc.Index(),
		Mount:    filepath.Base(dst),
		MountDir: dst,
		Debug:    *verbose,
		Disk:     block(dst),
	}

	fs, err := fuse.NewFilesystem(opts)
	if err != nil {
		die(err)
	}

	ch := make(chan os.Signal, 1)

	signal.Notify(ch, syscall.SIGQUIT)

	go func() {
		for range ch {
			fmt.Print(fs.DebugString())
		}
	}()

	runtime.KeepAlive(fs)

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
