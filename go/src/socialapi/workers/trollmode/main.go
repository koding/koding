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

	r.SetContext(trollmode.NewController(r.Log))
	r.ListenFor(trollmode.MarkedAsTroll, (*trollmode.Controller).MarkedAsTroll)
	r.ListenFor(trollmode.UnMarkedAsTroll, (*trollmode.Controller).UnMarkedAsTroll)

	// too many eggs in an egg
	//  consider refactoring
	r.Listen()
	r.Wait()
}
