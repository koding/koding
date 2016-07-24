package main

import (
	"os"

	"github.com/canthefason/go-watcher"
)

func main() {
	params := watcher.ParseArgs(os.Args)

	w := watcher.MustRegisterWatcher(params)

	r := watcher.NewRunner()

	// wait for build and run the binary with given params
	go r.Run(params)
	b := watcher.NewBuilder(w, r)

	// build given package
	go b.Build(params)

	// listen for further changes
	go w.Watch()

	r.Wait()
}
