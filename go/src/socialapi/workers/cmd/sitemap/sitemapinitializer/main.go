package main

import (
	"fmt"
	"socialapi/config"
	feeder "socialapi/workers/sitemap/sitemapfeeder"

	"github.com/koding/runner"
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

	appConfig := config.MustRead(r.Conf.Path)

	conf := *r.Conf
	conf.Redis.DB = appConfig.Sitemap.RedisDB

	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	controller := feeder.New(r.Log, redisConn)

	if err := controller.Start(); err != nil {
		r.Log.Fatal("Could not finish sitemap initialization: %s", err)
	}

}
