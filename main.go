package main

import "github.com/koding/multiconfig"

func main() {
	conf := new(FuseConfig)
	multiconfig.New().MustLoad(conf)
}
