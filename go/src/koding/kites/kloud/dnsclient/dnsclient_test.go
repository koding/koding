package dnsclient

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"

	"github.com/mitchellh/goamz/aws"
)

var (
	dns         *Route53
	testDomain  = "kloud-test.dev.koding.io"
	testDomain2 = "kloud-test2.dev.koding.io"
	testIP      = "127.0.0.1"
	testIP2     = "127.0.0.2"
)

func init() {
	auth, err := aws.EnvAuth()
	if err != nil {
		panic(err)
	}

	dns = NewRoute53Client("dev.koding.io", auth)
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
