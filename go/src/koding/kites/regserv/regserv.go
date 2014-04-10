package main

import (
	"flag"
	"io/ioutil"
	"log"
	"time"

	"koding/db/mongodb/modelhelper"
	kodingconfig "koding/tools/config"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/regserv"
)

var (
	profile = flag.String("c", "", "Configuration profile")
	region  = flag.String("r", "", "Region")
	ip      = flag.String("ip", "0.0.0.0", "Listen IP")
	port    = flag.Int("port", 3998, "Port")
)

func main() {
	flag.Parse()
	if *profile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}
	if *region == "" {
		log.Fatal("Please specify region via -r. Aborting.")
	}

	kodingConf := kodingconfig.MustConfig(*profile)

	pubKey, err := ioutil.ReadFile(kodingConf.NewKontrol.PublicKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	privKey, err := ioutil.ReadFile(kodingConf.NewKontrol.PrivateKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	kiteConf := kiteconfig.MustGet()
	kiteConf.Environment = kodingConf.Environment
	kiteConf.Region = *region
	kiteConf.IP = *ip
	kiteConf.Port = *port

	s := regserv.New(kiteConf, string(pubKey), string(privKey))

	// Request must not be authenticated because clients do not have a
	// kite.key before they register. We will authenticate them in
	// "register" method handler.
	s.Server.Config.DisableAuthentication = true

	s.Authenticate = func(r *kite.Request) error {
		password, err := r.Client.TellWithTimeout("kite.getPass", 10*time.Minute, "Enter password: ")
		if err != nil {
			return err
		}

		_, err = modelhelper.CheckAndGetUser(r.Client.Kite.Username, password.MustString())
		return err
	}

	modelhelper.Initialize(kodingConf.Mongo)

	s.Run()
}
