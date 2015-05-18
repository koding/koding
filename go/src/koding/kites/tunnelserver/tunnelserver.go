package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
	"github.com/koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

type config struct {
	Port            int
	BaseVirtualHost string `required:"true"`
}

var (
	server = tunnel.NewServer()
)

func main() {
	conf := new(config)
	m := multiconfig.New()
	m.MustLoad(conf)

	k := kite.New("tunnelserver", "0.0.1")
	k.Config.DisableAuthentication = true
	k.Config.Port = conf.Port

	k.Handle("register", Register(conf.BaseVirtualHost))
	k.HandleHTTP("/{rest:.*}", server)

	k.Run()
}

func Register(baseVirtualHost string) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		log.Printf("registering user '%s'\n", r.Username)

		virtualHost := fmt.Sprintf("%s.%s", r.Username, baseVirtualHost)
		identifier := randomID(32)

		server.AddHost(virtualHost, identifier)
		log.Printf("tunnel added: %s\n", virtualHost)

		return registerResult{
			VirtualHost: virtualHost,
			Identifier:  identifier,
		}, nil
	}
}

// randomID generates a random string of the given length
func randomID(length int) string {
	r := make([]byte, length*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
