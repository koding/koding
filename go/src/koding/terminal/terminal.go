package terminal

import (
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/kite"
	"koding/tools/logger"
)

const (
	TERMINAL_NAME     = "terminal"
	TERMINAL_VERSION  = "0.0.1"
	sessionPrefix     = "koding"
	kodingScreenPath  = "/opt/koding/bin/screen"
	kodingScreenrc    = "/opt/koding/etc/screenrc"
	defaultScreenPath = "/usr/bin/screen"
)

var (
	log               = logger.New(TERMINAL_NAME)
	mongodbConn       *mongodb.MongoDB
	conf              *config.Config
	ErrInvalidSession = "ErrInvalidSession"
)

type Terminal struct {
	Kite     *kite.Kite
	Name     string
	Version  string
	Region   string
	LogLevel logger.Level
}

func New(c *config.Config) *Terminal {
	return &Terminal{}

	conf = c
	mongodbConn = mongodb.NewMongoDB(c.Mongo)
	modelhelper.Initialize(c.Mongo)

	return &Terminal{
		Name:    TERMINAL_NAME,
		Version: TERMINAL_VERSION,
	}
}

func (t *Terminal) Run() {
	if t.Region == "" {
		panic("region is not set for Oskite")
	}

	log.Info("Kite.go preperation started")
	kiteName := "terminal"
	if t.Region != "" {
		kiteName += "-" + t.Region
	}

	t.Kite = kite.New(kiteName, conf, true)

	log.Info("Terminal kite started. Go!")
	t.Kite.Run()
}
