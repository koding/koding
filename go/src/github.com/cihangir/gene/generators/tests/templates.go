package tests

// TestFuncs holds the template for the test functions
var TestFuncs = `// package testfunc contains various helpers to be used in tests. Included
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
}`

// MainTestsTemplate holds the test file template
var MainTestsTemplate = `
{{$ModuleName := ToLower .Schema.Title}}

package {{$ModuleName}}tests

import (
    "testing"
    "net/http"

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

{{range $defKey, $def := .Schema.Definitions}}

func with{{$defKey}}Client(tb testing.TB, f func(*{{$ModuleName}}client.{{$defKey}})) {
    client := createClient(tb)
    defer client.Close()

    f({{$ModuleName}}client.New{{$defKey}}(client))
}

{{end}}
`

// TestsTemplate holds the template for the test files
var TestsTemplate = `
{{$schema := .Schema}}
{{$title := $schema.Title}}

{{$StructName := ToUpperFirst $title}}
{{$ModuleName := ToLower .ModuleName}}

package {{$ModuleName}}tests

import (
    "testing"

    "golang.org/x/net/context"
)

{{range $funcKey, $funcValue := $schema.Functions}}
func Test{{$StructName}}{{$funcKey}}(t *testing.T) {
    with{{$StructName}}Client(t, func(c *{{$ModuleName}}client.{{$StructName}}){
        req := &{{Argumentize $funcValue.Properties.incoming}}{}
        res := &{{Argumentize $funcValue.Properties.outgoing}}{}
        ctx := context.Background()
        err := c.{{$funcKey}}(ctx, req, res)
        tests.Assert(t, err == nil, "Err should be nil while testing {{$StructName}}.{{$funcKey}}")
    })
}
{{end}}
`
