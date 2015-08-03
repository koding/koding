package logfetcher

import (
	"log"
	"testing"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

var (
	lf     *kite.Kite
	remote *kite.Client
)

func init() {
	lf := kite.New("logfetcher", "0.0.1")
	lf.Config.DisableAuthentication = true
	lf.Config.Port = 3639
	lf.HandleFunc("fetch", Fetch)

	go lf.Run()
	<-lf.ServerReadyNotify()

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = "remote"
	remote = remoteKite.NewClient("http://127.0.0.1:3639/kite")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestFetch(t *testing.T) {
	t.Error("not implemented yet")
}
