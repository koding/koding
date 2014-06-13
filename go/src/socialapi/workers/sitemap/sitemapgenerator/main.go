package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"

	"socialapi/workers/sitemap/sitemapgenerator/generator"
)

var (
	Name = "SitemapGenerator"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	controller, err := generator.New(r.Log)
	if err != nil {
		r.Log.Error("Could not create sitemap generator: %s", err)
	}

	r.ShutdownHandler = controller.Shutdown
	r.Wait()
}
