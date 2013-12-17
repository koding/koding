package main

import (
	"flag"
	"fmt"
	"koding/newkite/kd/util"
	"koding/newkite/kite"
	"koding/newkite/kodingkey"
	"log"
)

var port = flag.String("port", "5555", "port to bind itself")

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "kodingclient",
		Version:     "0.0.1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "127.0.0.1",
	}

	k := kite.New(options)

	k.RegisterToKontrol = false // we'll going to work only in localhost
	k.DisableAuthentication()

	k.HandleFunc("info", info)

	k.Run()
}

func info(r *kite.Request) (interface{}, error) {
	hostID, err := util.HostID()
	if err != nil {
		return nil, err
	}

	var key string
	keyExist := false

	key, err = util.GetKey()
	if err != nil {
		k, err := kodingkey.NewKodingKey()
		if err != nil {
			return nil, err
		}

		key = k.String()
	} else {
		fmt.Printf("Found a key under '%s'. Going to use it to register\n", util.GetKdPath())
		keyExist = true
	}

	cb := func(r *kite.Request) {
		if !r.Args.One().MustBool() {
			fmt.Println("not authorized")
		}

		fmt.Println("got registered")

		if keyExist {
			return
		}

		err := util.WriteKey(key)
		if err != nil {
			log.Println(err)
		}
	}

	auth := Auth{
		Key:    key,
		HostID: hostID,
		CB:     cb,
	}

	fmt.Printf("sending auth '%+v' to %s\n", auth, r.Username)
	return auth, nil
}

type Auth struct {
	Key    string        `json:"key"`
	HostID string        `json:"hostID"`
	CB     kite.Callback `json:"cb"`
}
