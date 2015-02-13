package main

import (
	"fmt"
	"socialapi/workers/collaboration/collaboration"
	"socialapi/workers/common/runner"
)

var (
	Name = "Collaboration"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	handler := collaboration.New(r.Log)
	r.SetContext(handler)
	r.ListenFor("collaboration.ping", (*collaboration.Controller).Ping)
	r.Listen()
	r.Wait()
}
