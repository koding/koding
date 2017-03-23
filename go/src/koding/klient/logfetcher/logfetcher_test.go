package logfetcher

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
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
		log.Fatalf("err")
	}

	remoteKite2 := kite.New("remote2", "0.0.1")
	remoteKite2.Config.Username = "remote2"
	remote2 = remoteKite2.NewClient("http://127.0.0.1:3639/kite")
	err = remote2.Dial()
	if err != nil {
		log.Fatalf("err")
	}
}

func makeTempAndCopy(copyFrom string) (dir, path string, err error) {
	tmpDir, err := ioutil.TempDir("", "logfetcher")
	if err != nil {
		return "", "", err
	}

	tmpFile := filepath.Join(tmpDir, "file")

	// Create a new file for testing, so we can test offsetting and watching.
	if err := testutil.FileCopy(copyFrom, tmpFile); err != nil {
		return "", "", err
	}

	return tmpDir, tmpFile, nil
}

func TestTail(t *testing.T) {
	tmpDir, tmpFile, err := makeTempAndCopy("testdata/testfile1.txt")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	var watchCount int
	var watchResult []string
	var watchMu sync.Mutex

	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		watchCount++
		line := r.One().MustString()

		watchMu.Lock()
		watchResult = append(watchResult, line)
		watchMu.Unlock()
	})

	_, err = remote.Tell("tail", &Request{
		Path:  tmpFile,
		Watch: watchFunc,
	})
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("Waiting for the results..")
	time.Sleep(time.Second * 1)

	// Should return empty by default, since no new lines were given.
	watchMu.Lock()
	n := len(watchResult)
	watchMu.Unlock()

	if n != 0 {
		t.Errorf("WatchFunc should not be called for pre-existing lines.\nWant: 0\nGot : %d\n", n)
	}

	file, err := os.OpenFile(tmpFile, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}

	file.WriteString("Tail2\n")
	file.WriteString("Tail3\n")
	file.WriteString("Tail4\n")
	file.Close()

	// wait so the watch function picked up the tail changes
	time.Sleep(time.Second * 5)

	var modifiedLines = []string{"Tail2", "Tail3", "Tail4"}

	watchMu.Lock()
	if !reflect.DeepEqual(modifiedLines, watchResult) {
		err = fmt.Errorf("\nWatchFunc should not be called for pre-existing lines.\n"+
			"Want: %#v\nGot : %#v\n", modifiedLines, watchResult)
	}
	watchMu.Unlock()

	if err != nil {
		t.Error(err)
	}
}

// TestMultipleTail compares two log.tail calls on a single file, and ensures that
// they both receive the same input.
func TestMultipleTail(t *testing.T) {
	tmpDir, tmpFile, err := makeTempAndCopy("testdata/testfile2.txt")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	watchResult := []string{}
	watchFunc := dnode.Callback(func(r *dnode.Partial) {
		line := r.One().MustString()
		watchResult = append(watchResult, line)
	})

	_, err = remote.Tell("tail", &Request{
		Path:  tmpFile,
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
		Path:  tmpFile,
		Watch: watchFunc2,
	})
	if err != nil {
		t.Fatal(err)
	}

	time.Sleep(time.Second * 2)

	file, err := os.OpenFile(tmpFile, os.O_APPEND|os.O_WRONLY, 0600)
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

func TestTailOffset(t *testing.T) {
	t.Skip("this test is correct but prefetcher implementation is not: #10840")

	tmpDir, tmpFile, err := makeTempAndCopy("testdata/testfile1.txt")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	var (
		offset    = 3 // Read the last 3 lines of the file.
		linesC    = make(chan string, 10)
		watchFunc = dnode.Callback(func(r *dnode.Partial) {
			linesC <- r.One().MustString()
		})
	)

	if _, err = remote.Tell("tail", &Request{
		Path:       tmpFile,
		Watch:      watchFunc,
		LineOffset: offset,
	}); err != nil {
		t.Fatal(err)
	}

	// Write some data to file
	file, err := os.OpenFile(tmpFile, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}

	for _, data := range []string{"DataA\n", "DataB\n"} {
		if _, err = file.WriteString(data); err != nil {
			t.Fatal(err)
		}
	}

	if err = file.Close(); err != nil {
		t.Fatal(err)
	}

	t.Log("....Waiting for the results..")
	var offsetAll = offset + 2 // We wrote two more lines.
	lines := make([]string, 0, offsetAll)
	for i := 0; i < offsetAll; i++ {
		select {
		case line := <-linesC:
			t.Log(line)
			lines = append(lines, line)
		case <-time.After(2 * time.Second): // Wait each time.
			t.Fatalf("test timed out after %v", 2*time.Second)
		}
	}

	// Read the file, and get the offset lines to compare against.
	sourceText, err := ioutil.ReadFile(tmpFile)
	if err != nil {
		t.Fatal(err)
	}
	// wait so the watch function picked up the tail changes
	offsetLines := strings.Split(strings.TrimSpace(string(sourceText)), "\n")
	offsetLines = offsetLines[len(offsetLines)-offsetAll:]
	if !reflect.DeepEqual(offsetLines, lines) {
		t.Errorf("want offset lines = %#v\n; got %#v\n", offsetLines, lines)
	}
}

func TestGetOffsetLines(t *testing.T) {
	tmpDir, tmpFile, err := makeTempAndCopy("testdata/testfile1.txt")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	// Read the file, and get the offset lines to compare against.
	sourceText, err := ioutil.ReadFile(tmpFile)
	if err != nil {
		t.Fatal(err)
	}
	sourceLines := strings.Split(strings.TrimSpace(string(sourceText)), "\n")

	// Open our file, to pass to the func
	file1, err := os.Open(tmpFile)
	if err != nil {
		t.Fatal(err)
	}
	defer file1.Close()

	offset := 3
	result, err := GetOffsetLines(file1, 4, offset)
	if err != nil {
		t.Error(err)
	}

	expected := sourceLines[len(sourceLines)-offset:]
	if !reflect.DeepEqual(expected, result) {
		t.Errorf(
			"\nIt should return offset lines.\nWant: %#v\nGot : %#v\n",
			expected, result,
		)
	}

	// Set the offset to the entire file.
	offset = len(sourceLines) + 1
	result, err = GetOffsetLines(file1, 4, offset)
	if err != nil {
		t.Error(err)
	}

	expected = sourceLines
	if !reflect.DeepEqual(expected, result) {
		t.Errorf(
			"\nIt should return all the lines, if offset is larger than total.\nWant: %#v\nGot : %#v\n",
			expected, result,
		)
	}

	// Create the 2nd test file to be empty (Create truncates by default)
	file2, err := os.Create(tmpFile)
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println("Requesting empty lines")
	offset = 3
	result, err = GetOffsetLines(file2, 4, offset)
	if err != nil {
		t.Error(err)
	}

	expected = nil
	if !reflect.DeepEqual(expected, result) {
		t.Errorf(
			"\nIt should callback with no lines.\nWant: %#v\nGot : %#v\n",
			expected, result,
		)
	}

	tmpDir2, tmpFile, err := makeTempAndCopy("testdata/testfile1.txt")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir2)

	// Open our file, to pass to the func
	file1, err = os.Open(tmpFile)
	if err != nil {
		t.Fatal(err)
	}
	defer file1.Close()

	offset = 3
	result, err = GetOffsetLines(file1, defaultOffsetChunkSize, offset)
	if err != nil {
		t.Error(err)
	}

	expected = sourceLines[len(sourceLines)-offset:]
	if !reflect.DeepEqual(expected, result) {
		t.Errorf(
			"\nIt should return offset lines with a chunkSize larger than the file.\nWant: %#v\nGot : %#v\n",
			expected, result,
		)
	}
}
