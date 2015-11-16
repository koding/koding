package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"koding/artifact"
	"koding/kites/common"
	dnsclient "koding/kites/kloud/pkg/dnsclient"
	"os"

	"github.com/koding/ec2dynamicdata"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
	"github.com/koding/tunnel"
	"github.com/mitchellh/goamz/aws"
)

const Name = "tunnelserver"

type registerResult struct {
	VirtualHost string
	Identifier  string
}

type tunnelServer struct {
	Port            int
	Debug           bool
	BaseVirtualHost string `required:"true"`

	// ServerAddr is public Address of the running server. Like an assigned Elastic IP
	ServerAddr string

	HostedZone string
	AccessKey  string
	SecretKey  string

	// internal
	Log    logging.Logger
	Server *tunnel.Server
	Dns    *dnsclient.Route53
}

func main() {
	t := new(tunnelServer)
	m := multiconfig.New()
	m.MustLoad(t)
	m.MustValidate(t)

	auth := aws.Auth{
		AccessKey: t.AccessKey,
		SecretKey: t.SecretKey,
	}

	// get from ec2 meta-data if it's not passed explicitly
	if t.ServerAddr == "" {
		var err error
		t.ServerAddr, err = ec2dynamicdata.GetMetadata(ec2dynamicdata.PublicIPv4)
		if err != nil {
			fmt.Fprintf(os.Stderr, err.Error())
			os.Exit(1)
		}
	}

	var err error
	t.Server, err = tunnel.NewServer(&tunnel.ServerConfig{
		Debug: t.Debug,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, err.Error())
		os.Exit(1)
	}

	t.Dns = dnsclient.NewRoute53Client(t.HostedZone, auth)
	t.Log = common.NewLogger("tunnelkite", t.Debug)

	k := kite.New(Name, "0.0.1")
	k.Config.DisableAuthentication = true
	k.Config.Port = t.Port

	k.HandleFunc("register", t.Register)
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())
	k.HandleHTTP("/{rest:.*}", t.Server)

	k.Run()
}

func (t *tunnelServer) Register(r *kite.Request) (interface{}, error) {
	virtualHost := fmt.Sprintf("%s.%s", r.Username, t.BaseVirtualHost)
	identifier := randomID(32)

	domain := r.Username + "." + t.Dns.HostedZone()

	t.Log.Debug("Adding domain '%s' with to IP Address '%s'", domain, t.ServerAddr)
	if err := t.Dns.Upsert(domain, t.ServerAddr); err != nil {
		return nil, err
	}

	t.Log.Debug("Adding host '%s' with identifer '%s'", virtualHost, identifier)
	t.Server.AddHost(virtualHost, identifier)

	// cleanup domain and delete in memory virtualhost
	t.Server.OnDisconnect(identifier, func() error {
		t.Log.Debug("Deleting host '%s' and domain '%s'", virtualHost, domain)
		t.Server.DeleteHost(virtualHost)
		return t.Dns.Delete(domain)
	})

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
