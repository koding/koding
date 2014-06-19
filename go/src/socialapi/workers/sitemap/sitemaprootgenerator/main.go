package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/sitemap/sitemaprootgenerator/rootgenerator"
)

var Name = "SitemapRootGenerator"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	controller, err := rootgenerator.New(r.Log)
	if err != nil {
		r.Log.Error("Could not start sitemap root generator: %s", err)
	}

	r.ShutdownHandler = controller.Shutdown
	r.Wait()
}
