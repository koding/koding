package tests

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"

	"testing"

	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestGenerateMainTestFileForModule(t *testing.T) {

	const expected = `package accounttests

import (
	"net/http"
	"testing"

	"github.com/youtube/vitess/go/rpcplus"
	"github.com/youtube/vitess/go/rpcplus/jsonrpc"
	"github.com/youtube/vitess/go/rpcwrap"
	"golang.org/x/net/context"
)

func createClient(tb testing.TB) *rpcplus.Client {
	client, err := rpcwrap.DialHTTP(
		"tcp",                  // network
		"localhost:3000",       // address
		"json",                 // codec name
		jsonrpc.NewClientCodec, // codec factory
		time.Second*10,         // timeout
		nil,                    // TLS config
	)
	tests.Assert(tb, err == nil, "Err while creating the client")
	return client
}

func withAccountClient(tb testing.TB, f func(*accountclient.Account)) {
	client := createClient(tb)
	defer client.Close()

	f(accountclient.NewAccount(client))
}

func withConfigClient(tb testing.TB, f func(*accountclient.Config)) {
	client := createClient(tb)
	defer client.Close()

	f(accountclient.NewConfig(client))
}

func withProfileClient(tb testing.TB, f func(*accountclient.Profile)) {
	client := createClient(tb)
	defer client.Close()

	f(accountclient.NewProfile(client))
}
`
	var s schema.Schema
	if err := json.Unmarshal([]byte(testdata.JSON1), &s); err != nil {
		t.Fatal(err.Error())
	}

	a, err := GenerateMainTestFileForModule(&s)
	equals(t, nil, err)
	equals(t, expected, string(a))
}

func TestGenerateTestFuncs(t *testing.T) {

	const expected = `// package testfunc contains various helpers to be used in tests. Included
// from: https://github.com/benbjohnson/testing
package tests

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"
)

// Assert fails the test if the condition is false.
func Assert(tb testing.TB, condition bool, msg string, v ...interface{}) {
	if !condition {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d: "+msg+"\033[39m\n\n", append([]interface{}{filepath.Base(file), line}, v...)...)
		tb.FailNow()
	}
}

// Ok fails the test if an err is not nil.
func Ok(tb testing.TB, err error) {
	if err != nil {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d: unexpected error: %s\033[39m\n\n", filepath.Base(file), line, err.Error())
		tb.FailNow()
	}
}

// Equals fails the test if exp is not equal to act.
func Equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
`
	var s schema.Schema
	if err := json.Unmarshal([]byte(testdata.JSON1), &s); err != nil {
		t.Fatal(err.Error())
	}

	a, err := GenerateTestFuncs(&s)
	equals(t, nil, err)
	equals(t, expected, string(a))
}

func TestGenerateTests(t *testing.T) {

	const expected = `package accounttests

import (
	"testing"

	"golang.org/x/net/context"
)

func TestAccountCreate(t *testing.T) {
	withAccountClient(t, func(c *accountclient.Account) {
		req := &models.Account{}
		res := &models.Account{}
		ctx := context.Background()
		err := c.Create(ctx, req, res)
		tests.Assert(t, err == nil, "Err should be nil while testing Account.Create")
	})
}

func TestAccountDelete(t *testing.T) {
	withAccountClient(t, func(c *accountclient.Account) {
		req := &models.Account{}
		res := &models.Account{}
		ctx := context.Background()
		err := c.Delete(ctx, req, res)
		tests.Assert(t, err == nil, "Err should be nil while testing Account.Delete")
	})
}

func TestAccountOne(t *testing.T) {
	withAccountClient(t, func(c *accountclient.Account) {
		req := &models.Account{}
		res := &models.Account{}
		ctx := context.Background()
		err := c.One(ctx, req, res)
		tests.Assert(t, err == nil, "Err should be nil while testing Account.One")
	})
}

func TestAccountSome(t *testing.T) {
	withAccountClient(t, func(c *accountclient.Account) {
		req := &models.Account{}
		res := &[]*models.Account{}
		ctx := context.Background()
		err := c.Some(ctx, req, res)
		tests.Assert(t, err == nil, "Err should be nil while testing Account.Some")
	})
}

func TestAccountUpdate(t *testing.T) {
	withAccountClient(t, func(c *accountclient.Account) {
		req := &models.Account{}
		res := &models.Account{}
		ctx := context.Background()
		err := c.Update(ctx, req, res)
		tests.Assert(t, err == nil, "Err should be nil while testing Account.Update")
	})
}
`
	s := &schema.Schema{}
	if err := json.Unmarshal([]byte(testdata.JSON1), s); err != nil {
		t.Fatal(err.Error())
	}

	s = s.Resolve(nil).Definitions["Account"]
	a, err := GenerateTests("Account", s)

	equals(t, nil, err)
	equals(t, expected, string(a))
}

func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.Fail()
	}
}
