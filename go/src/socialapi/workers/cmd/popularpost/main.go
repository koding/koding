package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/popularpost"
	"time"

	"github.com/jinzhu/now"
	"github.com/koding/runner"
)

var (
	Name = "PopularPost"
)

func init() {
	now.FirstDayMonday = true
}

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	config.MustRead(r.Conf.Path)

	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()
	// create context
	context := popularpost.New(r.Log, redisConn)

	go func() {
		for {
			endOfDay := now.EndOfDay().UTC()
			difference := time.Now().UTC().Sub(endOfDay)

			<-time.After(difference * -1)

			//TODO: remove hardcoded of 'koding' and 'public'
			//      get yesterday's daily buckets that exist in redis, create
			//      weekly bucket for those groups, channel names
			keyname := &popularpost.KeyName{
				GroupName: "koding", ChannelName: "public",
				Time: time.Now().UTC(),
			}

			context.CreateSevenDayBucket(keyname)
			context.ResetRegistry()
		}
	}()

	r.SetContext(context)
	r.Register(models.Interaction{}).OnCreate().Handle((*popularpost.Controller).InteractionSaved)
	r.Register(models.Interaction{}).OnDelete().Handle((*popularpost.Controller).InteractionDeleted)
	r.Listen()
	r.Wait()
}
