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

	conf := *r.Conf
	// different redis db is used for sitemap,
	conf.Redis.DB = r.Conf.Sitemap.RedisDB
	redisConn := helper.MustInitRedisConn(&conf)
	defer redisConn.Close()

	controller, err := generator.New(r.Log, redisConn)
	if err != nil {
		r.Log.Error("Could not create sitemap generator: %s", err)
	}

	r.ShutdownHandler = controller.Shutdown
	r.Wait()
}
