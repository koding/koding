package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	"github.com/coreos/go-log/log"
	"github.com/koding/kite"
	"github.com/koding/multiconfig"
	"github.com/koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

type config struct {
	Port int
}

var (
	baseVirtualHost = "test.arslan.kd.io"
	server          = tunnel.NewServer()
)

func main() {
	conf := new(config)
	multiconfig.New().MustLoad(conf)

	k := kite.New("tunnerlserver", "0.0.1")
	k.Config.Port = conf.Port

	k.HandleFunc("register", Register)
	k.HandleHTTP("/", server)

	k.Run()
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
