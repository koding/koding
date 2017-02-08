package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

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

	if len(os.Args) != 3 {
		die(usage)
	}

	dst, src := os.Args[1], os.Args[2]

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

	bc, err := fusetest.NewBindCache(dst, *tmp)
	if err != nil {
		die(err)
	}

	opts := &fuse.Opts{
		Cache:    bc,
		CacheDir: *tmp,
		Remote:   bc.Index(),
		Mount:    filepath.Base(src),
		MountDir: src,
		Debug:    *verbose,
	}

	fs, err := fuse.NewFilesystem(opts)
	if err != nil {
		die(err)
	}

	_ = fs

	select {}
}
