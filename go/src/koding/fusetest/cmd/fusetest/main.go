package main

import (
	"koding/fusetest"
	"koding/klient/remote/req"
	"log"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Pass machine name as arguments to run tests.")
	}

	opts := req.MountFolderOpts{
		NoIgnore:       false,
		NoPrefetchMeta: false,
		PrefetchAll:    false,
		NoWatch:        false,
	}

	// convey is interferering with flag parsing, so use args
	if len(os.Args) > 2 {
		// this allows passing of -test.v=true/other flags without cache arg
		if []rune(os.Args[2])[0] != []rune("-")[0] {
			opts.PrefetchAll = true
			opts.CachePath = os.Args[2]
		}
	}

	f, err := fusetest.NewFusetest(os.Args[1], opts)
	if err != nil {
		log.Fatal(err)
	}

	f.RunAllTests()
}
