package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/trollmode/trollmode"
)

var (
	Name = "TrollMode"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(trollmode.NewController(r.Log))
	r.Register(models.Account{}).On(trollmode.MarkedAsTrollEvent).Handle((*trollmode.Controller).MarkedAsTroll)
	r.Register(models.Account{}).On(trollmode.UnMarkedAsTrollEvent).Handle((*trollmode.Controller).UnMarkedAsTroll)
	r.Listen()
	r.Wait()
}
