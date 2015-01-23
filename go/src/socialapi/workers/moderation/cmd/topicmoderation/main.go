package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/moderation/topic"
)

var (
	Name = "topicmoderation"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(topic.NewController(r.Log))
	r.Register(models.Account{}).On(models.ModerationChannelCreateLink).Handle((*topic.Controller).CreateLink)
	r.Register(models.Account{}).On(models.ModerationChannelDeleteLink).Handle((*topic.Controller).UnLink)
	r.Register(models.Account{}).On(models.ModerationChannelBlacklist).Handle((*topic.Controller).Blacklist)
	r.Listen()
	r.Wait()
}
