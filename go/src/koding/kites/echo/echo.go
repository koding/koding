package main

import (
	"fmt"
	"koding/kodingkite"
	"koding/tools/config"

	"github.com/koding/kite"
)

func main() {
	c := config.MustConfig("vagrant")
	k := kodingkite.New(c, "echo", "0.0.1")
	k.HandleFunc("echo", func(r *kite.Request) (interface{}, error) {
		args := r.Args
		str := args.One().MustString()
		fmt.Println(str)
		return str, nil
	})
	k.Run()
}
