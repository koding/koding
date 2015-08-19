package main

import "socialapi/config"

var conf *config.Config

func init() {
	_, conf = initialize()
}
