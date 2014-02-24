package main

import (
	"flag"
	"koding/kite"
	"koding/kite/kd/util"
	"koding/kite/kodingkey"
	"os/exec"

	"github.com/op/go-logging"
)

var log *logging.Logger

func main() {
	flag.Parse()

	// We pick up 54321 because it's in dynamic range and no one uses it
	// http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
	options := &kite.Options{
		Kitename:              "kodingclient",
		Version:               "0.0.1",
		Port:                  "54321",
		Region:                "localhost",
		Environment:           "development",
		PublicIP:              "127.0.0.1",
		DisableAuthentication: true,
	}

	k := kite.New(options)
	log = k.Log

	openKodingRegister()

	k.KontrolEnabled = false // we'll going to work only in localhost
	k.HandleFunc("info", info)
	k.Run()
}

func openKodingRegister() {
	log.Info("checking if koding key exist")
	key, err := util.GetKey()
	if err == nil {
		log.Info("koding key exist, checking if for validity")
		// rename to util.AuthServerLocal to test it on local
		err := util.CheckKey(util.AuthServerLocal, key)
		if err == nil {
			log.Info("koding key is valid, this machine is already registered.")
			return
		}
	}

	// open browser to register the new key
	log.Info("open new tab to let the user registering himself and creating a new koding key")
	cmd := exec.Command("open", "http://localhost:3020/RegisterHostKey")
	_, err = cmd.CombinedOutput()
	if err != nil {
		log.Error(err.Error())
	}
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

		// writing existent key doesn't hurt us.
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
