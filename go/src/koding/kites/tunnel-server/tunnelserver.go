package main

import (
	"flag"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tunnel"
	"net/http"
)

var port = flag.String("port", "", "port to bind itself")
var log = kite.GetLogger()

func main() {
	flag.Parse()

	options := &protocol.Options{
		Kitename:    "tunnelserver",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
	}

	k := kite.New(options)
	k.HandleFunc("register", Register)
	k.Start()

	server := tunnel.NewServer()
	http.Handle("/", server)
	err := http.ListenAndServe(":7000", nil)
	if err != nil {
		log.Error(err.Error())
	}

}

func Register(r *kite.Request) (interface{}, error) {
	log.Info("user %s registerd", r.Username)
	return "done", nil
}
