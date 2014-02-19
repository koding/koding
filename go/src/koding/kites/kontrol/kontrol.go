package main

import (
	"flag"
	"io/ioutil"
	"kite"
	"kite/kontrol"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

var (
	profile     = flag.String("c", "", "Configuration profile")
	region      = flag.String("r", "", "Region")
	peersString = flag.String("p", "", "Peers (comma seperated)")
)

func main() {
	flag.Parse()
	if *profile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}
	if *region == "" {
		log.Fatal("Please specify region via -r. Aborting.")
	}

	conf := config.MustConfig(*profile)
	modelhelper.Initialize(conf.Mongo)

	kiteOptions := &kite.Options{
		Kitename:    "kontrol",
		Version:     "0.0.1",
		Port:        strconv.Itoa(conf.NewKontrol.Port),
		Environment: conf.Environment,
		Region:      *region,
	}

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
	if *peersString != "" {
		peers = strings.Split(*peersString, ",")
	}

	kon := kontrol.New(kiteOptions, hostname, datadir, peers, string(publicKey), string(privateKey))

	kon.AddAuthenticator("sessionID", authenticateFromSessionID)

	if conf.NewKontrol.UseTLS {
		kon.EnableTLS(conf.NewKontrol.CertFile, conf.NewKontrol.KeyFile)
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
