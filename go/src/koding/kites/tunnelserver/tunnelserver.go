package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"koding/kites/kloud/pkg/dnsclient"
	"log"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
	"github.com/koding/streamtunnel"
	"github.com/mitchellh/goamz/aws"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

type config struct {
	Port            int
	BaseVirtualHost string `required:"true"`
	Debug           bool

	// Public Address of the running server
	ServerAddr string

	HostedZone string
	AccessKey  string
	SecretKey  string
}

type tunnelServer struct {
	BaseVirtualHost string
	server          *streamtunnel.Server
	dns             *dnsclient.Route53
}

func main() {
	conf := new(config)
	m := multiconfig.New()
	m.MustLoad(conf)

	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	t := &tunnelServer{
		BaseVirtualHost: conf.BaseVirtualHost,
		server: streamtunnel.NewServer(&streamtunnel.ServerConfig{
			Debug: conf.Debug,
		}),
		dns: dnsclient.NewRoute53Client(conf.HostedZone, auth),
	}

	k := kite.New("tunnelserver", "0.0.1")
	k.Config.DisableAuthentication = true
	k.Config.Port = conf.Port

	k.HandleFunc("register", t.Register)
	k.HandleHTTP("/{rest:.*}", t.server)

	k.Run()
}

func (t *tunnelServer) Register(r *kite.Request) (interface{}, error) {
	log.Printf("registering user '%s'\n", r.Username)

	virtualHost := fmt.Sprintf("%s.%s", r.Username, t.BaseVirtualHost)
	identifier := randomID(32)

	t.server.AddHost(virtualHost, identifier)
	log.Printf("tunnel added: %s\n", virtualHost)

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
