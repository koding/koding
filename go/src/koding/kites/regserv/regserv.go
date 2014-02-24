package main

import (
	"flag"
	"io/ioutil"
	"koding/tools/config"
	"log"

	"github.com/koding/kite"
	"github.com/koding/kite/regserv"
)

var (
	profile = flag.String("c", "", "Configuration profile")
	region  = flag.String("region", "", "Region")
	ip      = flag.String("ip", "0.0.0.0", "Listen IP")
	port    = flag.String("port", "8080", "Port")

	conf *config.Config
)

func main() {
	flag.Parse()
	if *profile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}
	if *region == "" {
		log.Fatal("Please specify region via -r. Aborting.")
	}

	conf = config.MustConfig(*profile)

	pubKey, err := ioutil.ReadFile(conf.NewKontrol.PublicKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	privKey, err := ioutil.ReadFile(conf.NewKontrol.PrivateKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	backend := &exampleBackend{
		publicKey:  string(pubKey),
		privateKey: string(privKey),
	}

	server := regserv.New(backend)
	server.Environment = conf.Environment
	server.Region = *region
	server.PublicIP = *ip
	server.Port = *port

	server.Run()
}

type exampleBackend struct {
	publicKey, privateKey string
}

func (b *exampleBackend) Username() string   { return conf.NewKontrol.Username }
func (b *exampleBackend) KontrolURL() string { return conf.Client.RuntimeOptions.NewKontrol.Url }
func (b *exampleBackend) PublicKey() string  { return b.publicKey }
func (b *exampleBackend) PrivateKey() string { return b.privateKey }

// TODO authenticate with username and password
func (b *exampleBackend) Authenticate(r *kite.Request) (string, error) {
	return "koding-kites", nil
}
