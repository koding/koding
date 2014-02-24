package main

import (
	"crypto/rand"
	"encoding/base64"
	"flag"
	"fmt"
	"github.com/op/go-logging"
	"koding/kite"
	"koding/tunnel"
	"net/http"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

var (
	log             *logging.Logger
	baseVirtualHost = "test.arslan.kd.io"
	server          = tunnel.NewServer()
)

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "tunnelserver",
		Version:     "0.0.1",
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "newkontrol.sj.koding.com",
	}

	k := kite.New(options)
	log = k.Log

	k.HandleFunc("register", Register)
	k.Start()

	http.Handle("/", server)
	err := http.ListenAndServe(":80", nil)
	if err != nil {
		log.Error(err.Error())
	}

}

func Register(r *kite.Request) (interface{}, error) {
	log.Info("user %s registerd", r.Username)

	virtualHost := fmt.Sprintf("%s.%s", r.Username, baseVirtualHost)
	identifier := randomID(32)

	server.AddHost(virtualHost, identifier)
	log.Info("tunnel added: %s", virtualHost)

	return registerResult{
		VirtualHost: virtualHost,
		Identifier:  identifier,
	}, nil
}

// randomID generates a random string of the given length
func randomID(length int) string {
	r := make([]byte, length*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
