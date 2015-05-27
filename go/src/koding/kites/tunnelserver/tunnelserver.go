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

type tunnelServer struct {
	Port            int
	Debug           bool
	BaseVirtualHost string `required:"true"`
	// Public Address of the running server
	ServerAddr string

	HostedZone string
	AccessKey  string
	SecretKey  string

	server *streamtunnel.Server
	dns    *dnsclient.Route53
}

func main() {
	t := new(tunnelServer)
	m := multiconfig.New()
	m.MustLoad(t)

	auth := aws.Auth{
		AccessKey: t.AccessKey,
		SecretKey: t.SecretKey,
	}

	t.dns = dnsclient.NewRoute53Client(t.HostedZone, auth)
	t.server = streamtunnel.NewServer(&streamtunnel.ServerConfig{
		Debug: t.Debug,
	})

	k := kite.New("tunnelserver", "0.0.1")
	k.Config.DisableAuthentication = true
	k.Config.Port = t.Port

	k.HandleFunc("register", t.Register)
	k.HandleHTTP("/{rest:.*}", t.server)

	k.Run()
}

func (t *tunnelServer) Register(r *kite.Request) (interface{}, error) {
	log.Printf("registering user '%s'\n", r.Username)

	virtualHost := fmt.Sprintf("%s.%s", r.Username, t.BaseVirtualHost)
	identifier := randomID(32)

	domain := r.Username + "." + t.dns.HostedZone()

	if err := t.dns.Upsert(domain, t.ServerAddr); err != nil {
		return nil, err
	}

	t.server.AddHost(virtualHost, identifier)

	// cleanup domain and delete in memory virtualhost
	t.server.OnDisconnect(identifier, func() error {
		t.server.DeleteHost(virtualHost)
		return t.dns.Delete(domain)
	})

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
