package vagrant

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/vagrantutil"
)

var (
	vagrantKite  *kite.Kite
	remote       *kite.Client
	localVagrant *vagrantutil.Vagrant
	vagrantName  = "vagrantTest"
	handlers     *Handlers
)

func TestMain(m *testing.M) {
	vagrantKite = kite.New("vagrant", "0.0.1")
	vagrantKite.Config.DisableAuthentication = true
	vagrantKite.Config.Port = 3640

	var err error
	localVagrant, err = vagrantutil.NewVagrant(vagrantName)
	if err != nil {
		log.Fatalln(err)
	}

	handlers = NewHandlers()

	vagrantKite.HandleFunc("list", handlers.List)
	vagrantKite.HandleFunc("create", handlers.Create)
	vagrantKite.HandleFunc("destroy", handlers.Destroy)
	vagrantKite.HandleFunc("halt", handlers.Halt)
	vagrantKite.HandleFunc("status", handlers.Status)
	vagrantKite.HandleFunc("up", handlers.Up)
	vagrantKite.HandleFunc("version", handlers.Version)

	go vagrantKite.Run()
	<-vagrantKite.ServerReadyNotify()

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = "remote"
	remote = remoteKite.NewClient("http://127.0.0.1:3640/kite")
	err = remote.Dial()
	if err != nil {
		log.Fatal("err")
	}

	// run our tests...
	exitStatus := m.Run()

	os.Exit(exitStatus)
}

func TestPath(t *testing.T) {
	methods := []string{"list", "create", "destroy", "halt", "status", "up", "version"}
	for _, name := range methods {
		_, err := remote.Tell(name, struct{ Path string }{})
		if err != nil {
			// all methods should return "path is missing" if no paths are passed
			if !strings.Contains(err.Error(), "path is missing") {
				t.Error(err)
			}
		}
	}
}

func TestWatch(t *testing.T) {
	msg := []string{"I", "love", "Coffee"}
	fakeFunc := func() (<-chan *vagrantutil.CommandOutput, error) {
		ch := make(chan *vagrantutil.CommandOutput, 3)
		for _, m := range msg {
			ch <- &vagrantutil.CommandOutput{
				Line: m,
			}
		}

		return ch, nil
	}

	// add fake handler, what matters is how `watchCommand` is working.
	vagrantKite.HandleFunc("fakeWatch", func(r *kite.Request) (interface{}, error) {
		fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
			return watchCommand(r, fakeFunc)
		}
		return handlers.withPath(r, fn)
	})

	reMsgs := []string{}
	watch := dnode.Callback(func(r *dnode.Partial) {
		msg := r.One().MustString()
		reMsgs = append(reMsgs, msg)
	})

	_, err := remote.Tell("fakeWatch", struct {
		Path  string
		Watch dnode.Function
	}{
		Path:  vagrantName,
		Watch: dnode.Function(watch),
	})
	if err != nil {
		t.Fatal(err)
	}

	// wait so  our callback can connect the messages
	time.Sleep(time.Second * 1)

	equals(t, msg, reMsgs)
}

func TestVersionHandler(t *testing.T) {
	vagrantVersion, err := localVagrant.Version()
	if err != nil {
		t.Fatal(err)
	}

	out, err := remote.Tell("version", struct {
		Path string
	}{
		Path: vagrantName,
	})
	if err != nil {
		t.Fatal(err)
	}

	handlerVersion := out.MustString()

	if handlerVersion != vagrantVersion {
		t.Errorf("\nWrong version mismatch from Kite response\n\tWant: %s\n\tGot : %s\n",
			vagrantVersion, handlerVersion)
	}
}

// equals fails the test if exp is not equal to act.
func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
