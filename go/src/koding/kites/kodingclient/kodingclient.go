package main

import (
	"flag"
	"koding/newkite/kd/util"
	"koding/newkite/kite"
	"koding/newkite/kodingkey"
	"os/exec"

	"github.com/op/go-logging"
)

var log *logging.Logger

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "kodingclient",
		Version:     "0.0.1",
		Port:        "5555",
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "127.0.0.1",
	}

	k := kite.New(options)
	log = k.Log

	k.RegisterToKontrol = false // we'll going to work only in localhost
	k.DisableAuthentication()

	k.HandleFunc("info", info)

	cmd := exec.Command("open", "https://localhost:3020/-/Hede")
	_, err := cmd.CombinedOutput()
	if err != nil {
		log.Error(err.Error())
	}

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
		log.Info("Found a key under '%s'. Going to use it to register", util.GetKdPath())
		keyExist = true
	}

	cb := func(r *kite.Request) {
		if !r.Args.One().MustBool() {
			log.Info("not authorized")
		}

		log.Info("got registered")

		if keyExist {
			return
		}

		err := util.WriteKey(key)
		if err != nil {
			log.Error(err.Error())
		}
	}

	auth := Auth{
		Key:    key,
		HostID: hostID,
		CB:     cb,
	}

	log.Info("sending auth '%+v' to %s", auth, r.Username)
	return auth, nil
}

type Auth struct {
	Key    string        `json:"key"`
	HostID string        `json:"hostID"`
	CB     kite.Callback `json:"cb"`
}
