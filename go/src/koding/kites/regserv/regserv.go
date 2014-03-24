package main

import (
	"flag"
	"io/ioutil"
	"koding/tools/config"
	"log"

	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/regserv"
)

var (
	profile = flag.String("c", "", "Configuration profile")
	region  = flag.String("region", "", "Region")
	ip      = flag.String("ip", "0.0.0.0", "Listen IP")
	port    = flag.Int("port", 8080, "Port")

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

	kiteConf := kiteconfig.MustGet()
	kiteConf.Environment = conf.Environment
	kiteConf.Region = *region
	kiteConf.IP = *ip
	kiteConf.Port = *port

	server := regserv.New(kiteConf, string(pubKey), string(privKey))

	server.Run()
}
