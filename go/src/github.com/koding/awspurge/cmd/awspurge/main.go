package main

import (
	"fmt"
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
	m := multiconfig.New()
	m.MustLoad(conf)

	fmt.Printf("conf = %+v\n", conf)

	p, err := awspurge.New(conf)
	if err != nil {
		return err
	}

	return p.Do()
}
