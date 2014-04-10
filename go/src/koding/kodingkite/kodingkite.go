package kodingkite

import (
	"errors"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
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
	Kontrol          *kontrolclient.KontrolClient
	Registration     *registration.Registration
	KodingConfig     *kodingconfig.Config
	registerHostname string
	scheme           string
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
		scheme:       "ws",
	}

	syslog, err := logging.NewSyslogHandler(name)
	if err != nil {
		log.Fatalf("Cannot connect to syslog: %s", err.Error())
	}

	kk.Log.SetHandler(logging.NewMultiHandler(logging.StderrHandler, syslog))

	if kodingConf.NewKites.UseTLS {
		kk.Server.UseTLSFile(kodingConf.NewKites.CertFile, kodingConf.NewKites.KeyFile)
		kk.scheme = "wss"
		kk.registerHostname, err = os.Hostname()
	} else {
		kk.registerHostname, err = getRegisterIP(kodingConf.Environment)
	}

	if err != nil {
		return nil, err
	}

	return kk, nil
}

func (k *KodingKite) Start() {
	k.Log.Info("Kite has started: %s", k.Kite.Kite())

	registerWithURL := &url.URL{
		Scheme: k.scheme,
		Host:   k.registerHostname + ":" + strconv.Itoa(k.Config.Port),
		// Put the kite's name and version into path because it is useful
		// on Chrome Console when developing.
		Path: "/" + k.Kite.Kite().Name + "-" + k.Kite.Kite().Version,
	}

	connected, err := k.Kontrol.DialForever()
	if err != nil {
		k.Server.Log.Fatal("Cannot dial kontrol: %s", err.Error())
	}
	k.Server.Start()
	go func() {
		<-connected
		k.Registration.RegisterToKontrol(registerWithURL)
	}()
}

func (k *KodingKite) Run() {
	k.Start()
	<-k.Server.CloseNotify()
}

func (k *KodingKite) Close() {
	k.Kontrol.Close()
	k.Server.Close()
}

func getRegisterIP(environment string) (string, error) {
	var ip string

	switch environment {
	case "production":
		fallthrough
	case "staging":
		// Magical IP address of Openstack Metadata Service
		// http://docs.openstack.org/grizzly/openstack-compute/admin/content/metadata-service.html
		resp, err := http.Get("http://169.254.169.254/latest/meta-data/public-ipv4")
		if err != nil {
			return "", errors.New("cannot get public IP address: " + err.Error())
		}

		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return "", errors.New("unexpected status code: " + resp.Status)
		}

		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return "", err
		}

		ip = string(body)
	case "vagrant":
		ip = "127.0.0.1"
	default:
		return "", errors.New("I don't know which IP address to register in this environment: " + environment)
	}

	if ip == "" {
		return "", errors.New("no suitable IP address is found")
	}

	return ip, nil
}
