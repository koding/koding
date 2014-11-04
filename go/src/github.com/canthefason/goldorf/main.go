// Goldorf is a command line tool inspired by fresh (https://github.com/pilu/fresh) and used
// for watching .go file changes, and restarting the app in case of an update/delete/add operation.
// After you installed it, you can run your apps with their default parameters as:
// goldorf -c config -p 7000 -h localhost
package main

import (
	"os"

	"github.com/canthefason/goldorf/watcher"
)

func main() {
	params := watcher.PrepareArgs(os.Args)

	w := watcher.MustRegisterWatcher(params)
	defer w.Close()

	done := make(chan struct{})

	r := watcher.NewRunner()

	// wait for build and run the binary with given params
	go r.Init(params)

	// build given package
	go watcher.Build(w, r, params)

	// force update for initial package build
	go w.ForceUpdate()

	// listen for further changes
	go w.ListenChanges()

	<-done
}
