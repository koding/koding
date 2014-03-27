package kodingkite

import (
	"log"
	"net/http"
	"net/url"
	"strconv"

	kodingconfig "koding/tools/config"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/kontrolclient"
	"github.com/koding/kite/registration"
	"github.com/koding/kite/server"
	"github.com/koding/logging"
)

type KodingKite struct {
	*server.Server
	Kontrol      *kontrolclient.KontrolClient
	Registration *registration.Registration
	KodingConfig *kodingconfig.Config
}

// New returns a new kite instance based on for the given Koding configurations
func New(kodingConf *kodingconfig.Config, name, version string) (*KodingKite, error) {
	kiteConf, err := kiteconfig.Get()
	if err != nil {
		return nil, err
	}

	kiteConf.Environment = kodingConf.Environment

	k := kite.New(name, version)
	k.Config = kiteConf

	server := server.New(k)

	kon := kontrolclient.New(k)

	kk := &KodingKite{
		Server:       server,
		Kontrol:      kon,
		Registration: registration.New(kon),
		KodingConfig: kodingConf,
	}

	syslog, err := logging.NewSyslogHandler(name)
	if err != nil {
		log.Fatalf("Cannot connect to syslog: %s", err.Error())
	}

	kk.Log.SetHandler(logging.NewMultiHandler(logging.StderrHandler, syslog))

	return kk, nil
}

func (s *KodingKite) Start() {
	s.Log.Info("Kite has started: %s", s.Kite.Kite())

	var ip string // we must register to kontrol with this IP address

	switch s.KodingConfig.Environment {
	case "production":
		// Magical IP address of Openstack Metadata Service
		// http://docs.openstack.org/grizzly/openstack-compute/admin/content/metadata-service.html
		resp, err := http.Get("http://169.254.169.254/latest/meta-data/public-ipv4")
		if err != nil {
			panic("cannot get public IP address: " + err.Error())
		}
		if resp.StatusCode != 200 {
			panic("unexpected status code: " + resp.Status)
		}
		body := make([]byte, 0)
		_, err = resp.Body.Read(body)
		if err != nil {
			panic(err)
		}
		ip = string(body)
	case "vagrant":
		ip = "127.0.0.1"
	default:
		panic("I don't know which IP address to register in this environment: " + s.KodingConfig.Environment)
	}

	if ip == "" {
		panic("no suitable IP address is found")
	}

	registerWithURL := &url.URL{
		Scheme: "ws",
		Host:   ip + ":" + strconv.Itoa(s.Config.Port),
		Path:   "/",
	}

	connected, err := s.Kontrol.DialForever()
	if err != nil {
		s.Server.Log.Fatal("Cannot dial kontrol: %s", err.Error())
	}
	s.Server.Start()
	go func() {
		<-connected
		s.Registration.RegisterToKontrol(registerWithURL)
	}()
}

func (s *KodingKite) Run() {
	s.Start()
	<-s.Server.CloseNotify()
}

func (s *KodingKite) Close() {
	s.Kontrol.Close()
	s.Server.Close()
}
