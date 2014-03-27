package kodingkite

import (
	"log"
	"net"
	"net/url"
	"strconv"
	"strings"

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
		addresses, err := net.InterfaceAddrs()
		if err != nil {
			panic("cannot get the address of local interfaces")
		}

		for _, addr := range addresses {
			if strings.HasPrefix(addr.String(), "172.16.") {
				ip = addr.String()
				break
			}
		}
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
