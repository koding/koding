package main

import "github.com/koding/logging"

func CreateLogger(name string, debug *bool) logging.Logger {

	log := logging.NewLogger(name)
}
