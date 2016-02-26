package logfetcher

import (
	"fmt"
	"log"
	"os"
	"reflect"
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

var (
	lf        *kite.Kite
	remote    *kite.Client
	remote2   *kite.Client
	testfile1 = "testdata/testfile1.txt.tmp"
	testfile2 = "testdata/testfile2.txt.tmp"
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

func createTestFiles() error {
	if err := testutil.FileCopy("testdata/testfile1.txt", testfile1); err != nil {
		return err
	}
	if err := testutil.FileCopy("testdata/testfile2.txt", testfile2); err != nil {
		return err
	}

	return nil
}

func TestTail(t *testing.T) {
	if err := createTestFiles(); err != nil {
		t.Fatal(err)
	}
	defer os.Remove(testfile1)
	defer os.Remove(testfile2)

	var watchCount int

	watchResult := []string{}
	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		watchCount++
		line := r.One().MustString()
		watchResult = append(watchResult, line)
	})

	_, err := remote.Tell("tail", &Request{
		Path:  testfile1,
		Watch: watchFunc,
	})
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("Waiting for the results..")
	time.Sleep(time.Second * 1)

	// Should return empty by default, since no new lines were given.
	if !reflect.DeepEqual([]string{}, watchResult) {
		t.Errorf(
			"\nWatchFunc should not be called for pre-existing lines.\nWant: %#v\nGot : %#v\n",
			[]string{}, watchResult,
		)
	}

	// Should not have called watcher at all
	if watchCount != 0 {
		t.Errorf(
			"\nWatchFunc should not be called for pre-existing lines.\nWanted %d calls, Got %d calls",
			0, watchCount,
		)
	}

	file, err := os.OpenFile(testfile1, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}

	file.WriteString("Tail2\n")
	file.WriteString("Tail3\n")
	file.Close()

	// wait so the watch function picked up the tail changes
	time.Sleep(time.Second * 1)

	modifiedLines := []string{"Tail2", "Tail3"}
	if !reflect.DeepEqual(modifiedLines, watchResult) {
		t.Errorf(
			"\nWatchFunc should not be called for pre-existing lines.\nWant: %#v\nGot : %#v\n",
			modifiedLines, watchResult,
		)
	}
}

// TestMultipleTail compares two log.tail calls on a single file, and ensures that
// they both receive the same input.
func TestMultipleTail(t *testing.T) {
	if err := createTestFiles(); err != nil {
		t.Fatal(err)
	}
	defer os.Remove(testfile1)
	defer os.Remove(testfile2)

	watchResult := []string{}
	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		line := r.One().MustString()
		watchResult = append(watchResult, line)
	})

	_, err := remote.Tell("tail", &Request{
		Path:  testfile2,
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
		Path:  testfile2,
		Watch: watchFunc2,
	})
	if err != nil {
		t.Fatal(err)
	}

	time.Sleep(time.Second * 2)

	file, err := os.OpenFile(testfile2, os.O_APPEND|os.O_WRONLY, 0600)
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
