package main

import (
	"fmt"
	"socialapi/config"

	"github.com/koding/runner"

	"socialapi/workers/sitemap/sitemapgenerator"
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

	appConfig := config.MustRead(r.Conf.Path)

	conf := *r.Conf
	// different redis db is used for sitemap,
	conf.Redis.DB = appConfig.Sitemap.RedisDB
	redisConn := runner.MustInitRedisConn(&conf)
	defer redisConn.Close()

	controller, err := generator.New(r.Log, redisConn)
	if err != nil {
		r.Log.Error("Could not create sitemap generator: %s", err)
	}

	r.ShutdownHandler = controller.Shutdown

	r.Listen()
	r.Wait()
}
