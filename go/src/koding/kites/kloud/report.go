package main

import (
	"fmt"
	"koding/kites/klient/usage"

	"github.com/koding/kite"
)

func Report(r *kite.Request) (interface{}, error) {
	fmt.Printf("Klient is reporting!!! %v", r.Client.Kite)

	var usg usage.Usage

	fmt.Printf("r.Args.raw %+v\n", string(r.Args.Raw))
	err := r.Args.One().Unmarshal(&usg)
	if err != nil {
		return nil, err
	}

	fmt.Printf("usage %+v\n", usg)
	return "I've got your message", nil
}
