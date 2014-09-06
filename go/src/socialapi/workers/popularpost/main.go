package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/popularpost/popularpost"
)

var (
	Name = "PopularPost"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// create context
	context := popularpost.New(r.Log, helper.MustInitRedisConn(r.Conf))

	go func() {
		//TODO: remove hardcoded of 'koding' and 'public'
		//      get yesterday's daily buckets that exist in redis, create
		//      weekly bucket for those groups, channel names
		context.CreateKeyAtStartOfDay("koding", "public")
		context.ResetRegistry()
	}()

	r.SetContext(context)
	r.Register(models.Interaction{}).OnCreate().Handle((*popularpost.Controller).InteractionSaved)
	r.Register(models.Interaction{}).OnDelete().Handle((*popularpost.Controller).InteractionDeleted)
	r.Listen()
	r.Wait()
}
