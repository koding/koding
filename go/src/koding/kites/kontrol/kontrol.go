package main

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"kite"
	"kite/kontrol"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"strconv"
)

var (
	profile = flag.String("c", "", "Configuration profile")
	region  = flag.String("r", "", "Region")
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

	// Read list of etcd servers from config.
	machines := make([]string, len(conf.Etcd))
	for i, s := range conf.Etcd {
		machines[i] = "http://" + s.Host + ":" + strconv.FormatUint(uint64(s.Port), 10)
	}

	publicKey, err := ioutil.ReadFile(conf.NewKontrol.PublicKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	privateKey, err := ioutil.ReadFile(conf.NewKontrol.PrivateKeyFile)
	if err != nil {
		log.Fatalln(err.Error())
	}

	kon := kontrol.New(kiteOptions, machines, string(publicKey), string(privateKey))

	kon.AddAuthenticator("kodingKey", authenticateFromKodingKey)
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

func authenticateFromKodingKey(r *kite.Request) error {
	username, err := findUsernameFromKey(r.Authentication.Key)
	if err != nil {
		return err
	}

	r.Username = username

	return nil
}

func findUsernameFromKey(key string) (string, error) {
	kodingKey, err := modelhelper.GetKodingKeysByKey(key)
	if err != nil {
		return "", errors.New("kodingkey not found in kontrol db")
	}

	account, err := modelhelper.GetAccountById(kodingKey.Owner)
	if err != nil {
		return "", fmt.Errorf("register get user err %s", err)
	}

	if account.Profile.Nickname == "" {
		return "", errors.New("nickname is empty, could not register kite")
	}

	return account.Profile.Nickname, nil
}
