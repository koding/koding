package logfetcher

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
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
	testFile := "testdata/testfile1.txt"

	initialText, err := ioutil.ReadFile(testFile)
	if err != nil {
		t.Fatal(err)
	}

	watchResult := []string{}
	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		line := r.One().MustString()
		watchResult = append(watchResult, line)
	})

	_, err = remote.Tell("fetch", &Request{
		Path:  testFile,
		Watch: watchFunc,
	})
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("Waiting for the results..")
	time.Sleep(time.Second * 1)

	lines := strings.Split(strings.TrimSpace(string(initialText)), "\n")
	if !reflect.DeepEqual(lines, watchResult) {
		t.Errorf("\nWant: %v\nGot : %v\n", lines, watchResult)
	}

	file, err := os.OpenFile(testFile, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}

	file.WriteString("Tail2\n")
	file.WriteString("Tail3\n")
	file.Close()

	modifiedText, err := ioutil.ReadFile(testFile)
	if err != nil {
		t.Fatal(err)
	}

	// wait so the watch function picked up the tail changes
	time.Sleep(time.Second * 1)

	fmt.Printf("watchResult = %+v\n", watchResult)

	modifiedLines := strings.Split(strings.TrimSpace(string(modifiedText)), "\n")
	if !reflect.DeepEqual(modifiedLines, watchResult) {
		t.Errorf("\nWant: %v\nGot : %v\n", modifiedLines, watchResult)
	}

}
