package dnsclient

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"testing"

	"github.com/mitchellh/goamz/aws"
)

var (
	dns        *DNS
	testDomain = "kloud-test.dev.koding.io"
	testIP     = "192.168.1.1"
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
		t.Error(err)
	}

	resp, err := http.Get("http://" + testDomain)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}

	fmt.Printf("string(data) = %+v\n", string(data))
}

func TestDelete(t *testing.T) {
	err := dns.Delete(testDomain, testIP)
	if err != nil {
		t.Error(err)
	}
}
