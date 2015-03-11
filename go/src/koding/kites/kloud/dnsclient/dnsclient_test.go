package dnsclient

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"

	"github.com/mitchellh/goamz/aws"
)

var (
	dns         *DNS
	testDomain  = "kloud-test.dev.koding.io"
	testDomain2 = "kloud-test2.dev.koding.io"
	testIP      = "192.168.1.1"
	testIP2     = "192.168.1.2"
)

func init() {
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	dns = New("dev.koding.io", auth)

	go func() {
		err := http.ListenAndServe(":8888", http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			io.WriteString(w, "hello, world!\n")
		}))
		log.Println(err)
	}()
}

func TestCreate(t *testing.T) {
	err := dns.Upsert(testDomain, testIP)
	if err != nil {
		t.Fatal(err)
	}

	record, err := dns.Get(testDomain)
	if err != nil {
		t.Fatal(err)
	}

	equals(t, testDomain, strings.TrimSuffix(record.Name, "."))
	equals(t, testIP, record.IP)
	equals(t, 30, record.TTL)

	// resp, err := http.Get("http://" + testDomain)
	// if err != nil {
	// 	t.Fatal(err)
	// }
	// defer resp.Body.Close()
	//
	// data, err := ioutil.ReadAll(resp.Body)
	// if err != nil {
	// 	t.Fatal(err)
	// }
	//
	// fmt.Printf("string(data) = %+v\n", string(data))
}

func TestUpdate(t *testing.T) {
	err := dns.Upsert(testDomain, testIP2)
	if err != nil {
		t.Error(err)
	}

	record, err := dns.Get(testDomain)
	if err != nil {
		t.Fatal(err)
	}

	equals(t, testDomain, strings.TrimSuffix(record.Name, "."))
	equals(t, testIP2, record.IP)
	equals(t, 30, record.TTL)

}

func TestRename(t *testing.T) {
	err := dns.Rename(testDomain, testDomain2)
	if err != nil {
		t.Error(err)
	}

	record, err := dns.Get(testDomain2)
	if err != nil {
		t.Fatal(err)
	}

	equals(t, testDomain2, strings.TrimSuffix(record.Name, "."))
	equals(t, testIP2, record.IP)
	equals(t, 30, record.TTL)

}

func TestDelete(t *testing.T) {
	err := dns.Delete(testDomain2)
	if err != nil {
		t.Error(err)
	}

	_, err = dns.Get(testDomain2)
	if err != ErrNoRecord {
		t.Errorf("Domain '%s' is deleted, but got a different error: %s", testDomain, err)
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
