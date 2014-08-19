package kontrol

import (
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"log"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
)

const Version = "0.0.6"

func New(c *Config) *kontrol.Kontrol {
	modelhelper.Initialize(c.MongoURL)

	publicKey, err := ioutil.ReadFile(FindPath(c.PublicKey))
	if err != nil {
		log.Fatalln(err.Error())
	}

	privateKey, err := ioutil.ReadFile(FindPath(c.PrivateKey))
	if err != nil {
		log.Fatalln(err.Error())
	}

	kiteConf := config.MustGet()

	if c.Environment != "" {
		kiteConf.Environment = c.Environment
	}

	if c.Region != "" {
		kiteConf.Region = c.Region
	}

	if c.Port != 0 {
		kiteConf.Port = c.Port
	}

	kon := kontrol.New(kiteConf, Version, string(publicKey), string(privateKey))
	kon.AddAuthenticator("sessionID", authenticateFromSessionID)
	kon.MachineAuthenticate = authenticateFromKodingPassword
	kon.Machines = c.Machines

	if c.TLSKeyFile != "" && c.TLSCertFile != "" {
		kon.Kite.UseTLSFile(c.TLSCertFile, c.TLSKeyFile)
	}

	return kon
}

func authenticateFromSessionID(r *kite.Request) error {
	username, err := findUsernameFromSessionID(r.Auth.Key)
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
