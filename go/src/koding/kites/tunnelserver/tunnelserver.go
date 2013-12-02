package main

import (
	"crypto/rand"
	"encoding/base64"
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/tunnel"
	"net/http"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

var (
	port            = flag.String("port", "", "port to bind itself")
	log             = kite.GetLogger()
	baseVirtualHost = "test.arslan.kd.io"
	server          = tunnel.NewServer()
)

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "tunnelserver",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
	}

	k := kite.New(options)
	k.HandleFunc("register", Register)
	k.Start()

	http.Handle("/", server)
	err := http.ListenAndServe(":7000", nil)
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
