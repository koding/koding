package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/sitemapfeeder/feeder"
)

var (
	Name = "SitemapInitializer"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	controller := feeder.New(r.Log)

	if err := controller.Start(); err != nil {
		r.Log.Fatal("Could not finish sitemap initialization: %s", err)
	}

}
