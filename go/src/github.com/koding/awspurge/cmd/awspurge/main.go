package main

import (
	"log"

	"github.com/koding/awspurge"
	"github.com/koding/multiconfig"
)

func main() {
	if err := runMain(); err != nil {
		log.Fatalln(err)
	}
}

func runMain() error {
	conf := &awspurge.Config{}
	m := multiconfig.NewWithPath(".awspurge.toml")
	m.MustLoad(conf)

	p, err := awspurge.New(conf)
	if err != nil {
		return err
	}

	return p.Do()
}
