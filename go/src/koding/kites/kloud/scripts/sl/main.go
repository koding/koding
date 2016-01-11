package main

import (
	"fmt"
	"os"

	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"
)

var (
	username = os.Getenv("SOFTLAYER_USER_NAME")
	apiKey   = os.Getenv("SOFTLAYER_API_KEY")

	client *sl.Softlayer
)

// Resources var is used to globally register each Softlayer resources handler.
var Resources = res.New("sl")

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	if username == "" {
		die("SOFTLAYER_USER_NAME is not set")
	}
	if apiKey == "" {
		die("SOFTLAYER_API_KEY is not set")
	}
	client = sl.NewSoftlayer(username, apiKey)
	if err := Resources.Main(os.Args[1:]); err != nil {
		die(err)
	}
}
