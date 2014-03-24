package main

import (
	_ "expvar"
	"flag"
	"fmt"
	"koding/tools/config"
	// Imported for side-effect of handling /debug/vars.
	"github.com/koding/logging"
	// "koding/tools/logger"
	_ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.
	"os"
	"os/signal"
	"socialapi/db"
	"socialapi/models"
	"socialapi/workers/api/handlers"
	"strings"
	"syscall"

	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/rcrowley/go-tigertonic"
)

var (
	Bongo       *bongo.Bongo
	log         = logging.NewLogger("FollowingFeedWorker")
	cert        = flag.String("cert", "", "certificate pathname")
	key         = flag.String("key", "", "private key pathname")
	flagConfig  = flag.String("config", "", "pathname of JSON configuration file")
	listen      = flag.String("listen", "127.0.0.1:8000", "listen address")
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	conf        *config.Config

	hMux       tigertonic.HostServeMux
	mux, nsMux *tigertonic.TrieServeMux
)

type context struct {
	Username string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: example [-cert=<cert>] [-key=<key>] [-config=<config>] [-listen=<listen>]")
		flag.PrintDefaults()
	}
	mux = tigertonic.NewTrieServeMux()
	mux = handlers.Inject(mux)
}

func setLogLevel() {
	var logLevel logging.Level

	if *flagDebug {
		logLevel = logging.DEBUG
	} else {
		logLevel = logging.INFO
	}
	log.SetLevel(logLevel)
}

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}
	conf = config.MustConfig(*flagProfile)
	setLogLevel()

	// Example of parsing a configuration file.
	// c := &config.Config{}
	// if err := tigertonic.Configure(*flagConfig, c); nil != err {
	// 	log.Fatal(err)
	// }

	server := newServer()
	// Example use of server.Close and server.Wait to stop gracefully.
	go listener(server)

	initBongo(conf)
	// createTables()

	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM)

	log.Info("Recieved %v", <-ch)

	// do not forgot to close the bongo connection
	Bongo.Close()

	// shutdown server
	server.Close()
}

func initBongo(c *config.Config) {
	bConf := &broker.Config{
		Host:     c.Mq.Host,
		Port:     c.Mq.Port,
		Username: c.Mq.ComponentUser,
		Password: c.Mq.Password,
		Vhost:    c.Mq.Vhost,
	}

	broker := broker.New(bConf, log)
	Bongo = bongo.New(broker, db.DB, log)
	err := Bongo.Connect()
	if err != nil {
		panic(err)
	}
}

func newServer() *tigertonic.Server {
	return tigertonic.NewServer(
		*listen,
		tigertonic.CountedByStatus(
			tigertonic.Logged(
				tigertonic.WithContext(mux, context{}),
				func(s string) string {
					return strings.Replace(s, "SECRET", "REDACTED", -1)
				},
			),
			"http",
			nil,
		),
	)
}

func listener(server *tigertonic.Server) {
	var err error
	if "" != *cert && "" != *key {
		err = server.ListenAndServeTLS(*cert, *key)
	} else {
		err = server.ListenAndServe()
	}
	if nil != err {
		panic(err)
	}
}

func createTables() {
	db.DB.LogMode(true)
	db.DB.Exec("drop table channel_message_list;")
	db.DB.Exec("drop table channel_message;")
	db.DB.Exec("drop table message_reply;")
	db.DB.Exec("drop table channel_participant;")
	db.DB.Exec("drop table channel;")
	db.DB.Exec("drop table interaction;")

	if err := db.DB.CreateTable(&models.ChannelMessage{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.MessageReply{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.Channel{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.ChannelMessageList{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.ChannelParticipant{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
	if err := db.DB.CreateTable(&models.Interaction{}).Error; err != nil {
		panic(fmt.Sprintf("No error should happen when create table, but got %+v", err))
	}
}
