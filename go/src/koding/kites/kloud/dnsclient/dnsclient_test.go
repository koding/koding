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
	dns        *DNS
	testDomain = "kloud-test.dev.koding.io"
	testIP     = "192.168.1.2"
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
	err := dns.Create(testDomain, testIP)
	if err != nil {
		t.Fatal(err)
	}

	record, err := dns.Get(testDomain)
	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(testIP, record.IP) {
		_, file, line, _ := runtime.Caller(0)
		fmt.Printf("%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\n\n", filepath.Base(file), line, testIP, record.IP)
		t.FailNow()
	}

	if !reflect.DeepEqual(30, record.TTL) {
		_, file, line, _ := runtime.Caller(0)
		fmt.Printf("%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\n\n", filepath.Base(file), line, 30, record.TTL)
		t.FailNow()
	}

	if !reflect.DeepEqual(testDomain, strings.TrimSuffix(record.Name, ".")) {
		_, file, line, _ := runtime.Caller(0)
		fmt.Printf("%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\n\n", filepath.Base(file), line, testDomain, record.Name)
		t.FailNow()
	}

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

func TestDelete(t *testing.T) {
	err := dns.Delete(testDomain, testIP)
	if err != nil {
		t.Error(err)
	}
}
