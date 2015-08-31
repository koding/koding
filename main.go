package main

import (
	"log"

	"github.com/koding/multiconfig"
)

func main() {
	conf := new(FuseConfig)
	multiconfig.New().MustLoad(conf)

	_, err := NewKlientTransport(conf.KlientIP)
	if err != nil {
		log.Fatal(err)
	}
}
