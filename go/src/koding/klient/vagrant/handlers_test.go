package vagrant

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/vagrantutil"
)

var (
	vagrantKite  *kite.Kite
	remote       *kite.Client
	localVagrant *vagrantutil.Vagrant
	vagrantName  = "vagrantTest"
	handlers     *Handlers
	home         = "./testdata"
)

func TestMain(m *testing.M) {
	vagrantKite = kite.New("vagrant", "0.0.1")
	vagrantKite.Config.DisableAuthentication = true
	vagrantKite.Config.Port = 3640
	vagrantKite.SetLogLevel(kite.DEBUG)

	var err error
	localVagrant, err = vagrantutil.NewVagrant(vagrantName)
	if err != nil {
		log.Fatalln(err)
	}

	handlers = NewHandlers(&Options{Home: home, Log: vagrantKite.Log})

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
		log.Fatalf("err")
	}

	// run our tests...
	exitStatus := m.Run()

	os.Exit(exitStatus)
}

func TestPath(t *testing.T) {
	methods := []string{"list", "create", "destroy", "halt", "status", "up", "version"}
	for _, name := range methods {
		_, err := remote.Tell(name, struct{ FilePath string }{})
		if err != nil {
			// all methods should return "path is missing" if no paths are passed
			if !strings.Contains(err.Error(), "[filePath] is missing") {
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
		close(ch)

		return ch, nil
	}

	// add fake handler, what matters is how `watchCommand` is working.
	vagrantKite.HandleFunc("fakeWatch", func(r *kite.Request) (interface{}, error) {
		fn := func(r *kite.Request, v *vagrantutil.Vagrant) (interface{}, error) {
			return handlers.watchCommand(r, "", fakeFunc)
		}
		return handlers.withPath(r, fn)
	})

	var reMsgs []string

	done := make(chan error, 1)

	success := dnode.Callback(func(r *dnode.Partial) {
		done <- nil
	})

	failure := dnode.Callback(func(r *dnode.Partial) {
		done <- errors.New(r.One().MustString())
	})

	output := dnode.Callback(func(r *dnode.Partial) {
		msg := r.One().MustString()
		reMsgs = append(reMsgs, msg)
	})

	_, err := remote.Tell("fakeWatch", struct {
		FilePath string
		Output   dnode.Function
		Success  dnode.Function
		Failure  dnode.Function
	}{
		FilePath: vagrantName,
		Success:  dnode.Function(success),
		Failure:  dnode.Function(failure),
		Output:   dnode.Function(output),
	})
	if err != nil {
		t.Fatal(err)
	}

	// wait so  our callback can connect the messages
	select {
	case err := <-done:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("timed out waiting for done")
	}

	equals(t, msg, reMsgs)
}

func TestVersionHandler(t *testing.T) {
	vagrantVersion, err := localVagrant.Version()
	if err != nil {
		t.Fatal(err)
	}

	out, err := remote.Tell("version", struct {
		FilePath string
	}{
		FilePath: vagrantName,
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
