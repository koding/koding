package main

import (
	"fmt"
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

	// create message handler
	handler := trollmode.NewTrollModeController(r.Log)

	r.Listen(handler)
	r.Close()
}
