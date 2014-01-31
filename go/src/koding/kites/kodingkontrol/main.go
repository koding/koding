package main

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kite"
	"koding/kite/kontrol"
	"koding/tools/config"
	"strconv"
)

func main() {
	kiteOptions := &kite.Options{
		Kitename:    "kontrol",
		Version:     "0.0.1",
		Port:        strconv.Itoa(config.Current.NewKontrol.Port),
		Region:      "sj",
		Environment: "development",
		Username:    "koding",
	}

	// Read list of etcd servers from config.
	machines := make([]string, len(config.Current.Etcd))
	for i, s := range config.Current.Etcd {
		machines[i] = "http://" + s.Host + ":" + strconv.FormatUint(uint64(s.Port), 10)
	}

	kon := kontrol.New(kiteOptions, machines)

	kon.AddAuthenticator("kodingKey", authenticateFromKodingKey)
	kon.AddAuthenticator("sessionID", authenticateFromSessionID)

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
