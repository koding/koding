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
	lf      *kite.Kite
	remote  *kite.Client
	remote2 *kite.Client
)

func init() {
	lf := kite.New("logfetcher", "0.0.1")
	lf.Config.DisableAuthentication = true
	lf.Config.Port = 3639
	lf.HandleFunc("tail", Tail)

	go lf.Run()
	<-lf.ServerReadyNotify()

	remoteKite := kite.New("remote", "0.0.1")
	remoteKite.Config.Username = "remote"
	remote = remoteKite.NewClient("http://127.0.0.1:3639/kite")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}

	remoteKite2 := kite.New("remote2", "0.0.1")
	remoteKite2.Config.Username = "remote2"
	remote2 = remoteKite2.NewClient("http://127.0.0.1:3639/kite")
	err = remote2.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestTail(t *testing.T) {
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

	_, err = remote.Tell("tail", &Request{
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

	modifiedLines := strings.Split(strings.TrimSpace(string(modifiedText)), "\n")
	if !reflect.DeepEqual(modifiedLines, watchResult) {
		t.Errorf("\nWant: %v\nGot : %v\n", modifiedLines, watchResult)
	}
}

func TestMultipleTail(t *testing.T) {
	testFile := "testdata/testfile2.txt"

	watchResult := []string{}
	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		line := r.One().MustString()
		watchResult = append(watchResult, line)
	})

	_, err := remote.Tell("tail", &Request{
		Path:  testFile,
		Watch: watchFunc,
	})
	if err != nil {
		t.Fatal(err)
	}

	watchResult2 := []string{}
	watchFunc2 := dnode.Callback(func(r *dnode.Partial) {
		line := r.One().MustString()
		watchResult2 = append(watchResult2, line)
	})

	_, err = remote2.Tell("tail", &Request{
		Path:  testFile,
		Watch: watchFunc2,
	})
	if err != nil {
		t.Fatal(err)
	}

	time.Sleep(time.Second * 2)

	file, err := os.OpenFile(testFile, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()

	file.WriteString("Tail2\n")
	file.WriteString("Tail3\n")

	// wait so the watch function picked up the tail changes
	time.Sleep(time.Second)
	t.Logf("watchResult = %+v\n", watchResult)
	t.Logf("watchResult2 = %+v\n", watchResult2)

	// Now check the new two results
	if !reflect.DeepEqual(
		watchResult[len(watchResult)-2:],
		watchResult2[len(watchResult2)-2:],
	) {
		t.Errorf("\nWant: %v\nGot : %v\n",
			watchResult[len(watchResult)-2:],
			watchResult2[len(watchResult2)-2:],
		)
	}

	// Now let us disconnect the second connection, we should receive any new
	// changes for watchResult2 (From watchFunc2) anymore

	currentWatchLen := len(watchResult)
	currentWatch2Len := len(watchResult2)
	remote2.Close()

	// wait so onDisconnect get recognized on Kite
	time.Sleep(time.Second)

	file.WriteString("Tail4\n")
	file.WriteString("Tail5\n")

	// wait so the watch function picked up the tail changes
	time.Sleep(time.Second)

	if currentWatch2Len != len(watchResult2) {
		t.Errorf("WatchFunc2 is still triggered, got %d should have %d", len(watchResult2), currentWatch2Len)
	}

	if currentWatchLen+2 != len(watchResult) {
		t.Errorf("WatchFunc2 is not triggered, got %d should have %d", len(watchResult), currentWatchLen+2)
	}

}
