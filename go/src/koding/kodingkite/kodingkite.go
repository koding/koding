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
	"github.com/koding/logging"
)

type KodingKite struct {
	*kite.Kite
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

	kk := &KodingKite{
		Kite:         k,
		KodingConfig: kodingConf,
		scheme:       "ws",
	}

	// prepare our multilog handler
	syslog, err := logging.NewSyslogHandler(name)
	if err != nil {
		log.Fatalf("Cannot connect to syslog: %s", err.Error())
	}

	logger := logging.NewLogger(name)
	logger.SetHandler(logging.NewMultiHandler(logging.StderrHandler, syslog))

	k.Log = logger
	k.SetLogLevel = func(l kite.Level) {
		logger.SetLevel(convertLevel(l))
	}

	if kodingConf.NewKites.UseTLS {
		kk.UseTLSFile(kodingConf.NewKites.CertFile, kodingConf.NewKites.KeyFile)
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

func (k *KodingKite) Run() {
	k.Log.Info("Kite has started: %s", k.Kite.Kite())

	registerWithURL := &url.URL{
		Scheme: k.scheme,
		Host:   k.registerHostname + ":" + strconv.Itoa(k.Kite.Config.Port),
		// Put the kite's name and version into path because it is useful
		// on Chrome Console when developing.
		Path: "/" + k.Kite.Kite().Name + "-" + k.Kite.Kite().Version,
	}

	go k.Kite.RegisterForever(registerWithURL)
	<-k.Kite.KontrolReadyNotify()

	k.Kite.Run()
}

func (k *KodingKite) Close() {
	k.Kite.Close()
}

func getRegisterIP(environment string) (string, error) {
	var ip string

	switch environment {
	case "production":
		fallthrough
	case "kodingme":
		fallthrough
	case "staging":
		// Magical IP address of Openstack Metadata Service
		// http://docs.openstack.org/grizzly/openstack-compute/admin/content/metadata-service.html
		resp, err := http.Get("http://echoip.com")
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

// convertLevel converst a kite level into logging level
func convertLevel(l kite.Level) logging.Level {
	switch l {
	case kite.DEBUG:
		return logging.DEBUG
	case kite.WARNING:
		return logging.WARNING
	case kite.ERROR:
		return logging.ERROR
	case kite.FATAL:
		return logging.CRITICAL
	default:
		return logging.INFO
	}
}
