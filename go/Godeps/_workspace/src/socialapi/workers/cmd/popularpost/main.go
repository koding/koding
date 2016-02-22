package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/popularpost"
	"time"

	"github.com/cenkalti/backoff"
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

	// this is here because at the end of each week if no one likes a message,
	// we wont be able to show any popular posts, calling CreateSevenDayBucket
	// will create bucket in redis and will populate posts
	go func() {
		for {
			endOfDay := now.EndOfDay().UTC()
			difference := endOfDay.Sub(time.Now().UTC())

			<-time.After(difference)

			if err := backoff.Retry(
				context.CreateWeeklyBuckets,
				backoff.NewExponentialBackOff(),
			); err != nil {
				r.Log.Error("Couldnt create weekly buckets", err.Error())
			}
		}
	}()

	r.SetContext(context)
	r.Register(models.Interaction{}).OnCreate().Handle((*popularpost.Controller).InteractionSaved)
	r.Register(models.Interaction{}).OnDelete().Handle((*popularpost.Controller).InteractionDeleted)
	r.Listen()
	r.Wait()
}
