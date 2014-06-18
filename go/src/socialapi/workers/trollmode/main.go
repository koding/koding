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

	// too many egg in an egg
	//  consider refactoring
	r.Listen(
		trollmode.NewManager(
			trollmode.NewController(
				r.Log,
			),
		),
	)
	r.Wait()
}
