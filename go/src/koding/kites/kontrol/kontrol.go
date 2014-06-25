package main

import (
	"flag"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
)

const version = "0.0.5"

var (
	flagProfile    = flag.String("c", "", "Configuration profile")
	flagRegion     = flag.String("r", "", "Region")
	flagPeerString = flag.String("p", "", "Peers (comma seperated)")
	flagPort       = flag.Int("port", 4000, "Port number of kontrol server")
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	if *flagRegion == "" {
		log.Fatal("Please specify region via -r. Aborting.")
	}

	conf := config.MustConfig(*flagProfile)
	modelhelper.Initialize(conf.Mongo)

	publicKey, err := ioutil.ReadFile(conf.NewKontrol.PublicKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	privateKey, err := ioutil.ReadFile(conf.NewKontrol.PrivateKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	hostname, err := os.Hostname()
	if err != nil {
		log.Fatalln(err.Error())
	}

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatalln(err.Error())
	}

	datadir := filepath.Join(cwd, "kontrol-data-"+hostname)

	var peers []string
	if *flagPeerString != "" {
		peers = strings.Split(*flagPeerString, ",")
	}

	kiteConf := kiteconfig.MustGet()
	kiteConf.Port = conf.NewKontrol.Port
	kiteConf.Environment = conf.Environment
	kiteConf.Region = *flagRegion
	kiteConf.Port = *flagPort

	kon := kontrol.New(kiteConf, version, string(publicKey), string(privateKey))
	kon.Peers = peers
	kon.DataDir = datadir

	kon.AddAuthenticator("sessionID", authenticateFromSessionID)
	kon.MachineAuthenticate = authenticateFromKodingPassword

	if conf.NewKontrol.UseTLS {
		kon.Kite.UseTLSFile(conf.NewKontrol.CertFile, conf.NewKontrol.KeyFile)
		kon.Kite.Config.Port = conf.NewKontrol.Port
	}

	kon.Run()
}

func authenticateFromSessionID(r *kite.Request) error {
	username, err := findUsernameFromSessionID(r.Authentication.Key)
	if err != nil {
		return err
	}

	r.Username = username

	return nil
}

func findUsernameFromSessionID(sessionID string) (string, error) {
	session, err := modelhelper.GetSession(sessionID)
	if err != nil {
		return "", err
	}

	return session.Username, nil
}

func authenticateFromKodingPassword(r *kite.Request) error {
	password, err := r.Client.TellWithTimeout(
		"kite.getPass",
		10*time.Minute,
		"Enter password: ",
	)

	if err != nil {
		return err
	}

	_, err = modelhelper.CheckAndGetUser(r.Client.Kite.Username, password.MustString())
	return err
}
