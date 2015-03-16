package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/runner"
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
