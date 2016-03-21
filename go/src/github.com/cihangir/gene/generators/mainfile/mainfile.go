package mainfile

import (
	"fmt"
	"text/template"

	"bytes"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type Generator struct{}

func New() *Generator {
	return &Generator{}
}

func (g *Generator) Name() string {
	return "statements"
}

// GenerateMainFile handles the main file generation for persistent
// connection rpc server
func (g *Generator) Generate(context *common.Context, schema *schema.Schema) ([]common.Output, error) {
	moduleName := context.ModuleNameFunc(schema.Title)
	outputs := make([]common.Output, 0)

	for _, def := range schema.Definitions {
		// create models only for objects
		if def.Type != nil {
			if t, ok := def.Type.(string); ok {
				if t != "object" {
					continue
				}
			}
		}

		f, err := generateMainFile(context, schema)
		if err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s%s/main.go",
			context.Config.Target,
			moduleName,
		)

		outputs = append(outputs, common.Output{
			Content: f,
			Path:    path,
		})

	}

	return outputs, nil

}

func generateMainFile(context *common.Context, s *schema.Schema) ([]byte, error) {
	const templateName = "mainfile.tmpl"
	temp := template.New(templateName).Funcs(context.TemplateFuncs)

	if _, err := temp.Parse(MainFileTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, templateName, data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// MainFileTemplate holds the template for the main file generation
var MainFileTemplate = `
package main

import (
    "fmt"
    "net/http"
    "github.com/youtube/vitess/go/rpcplus"
    "github.com/youtube/vitess/go/rpcplus/jsonrpc"
    "github.com/youtube/vitess/go/rpcwrap"
)

var (
    Name    = "{{.Schema.Title}}"
    VERSION string
)

var ContextCreator = func(req *http.Request) context.Context {
    return context.Background()
}

var Mux = http.NewServeMux()

func main() {

    {{$Name := .Schema.Title}}
    server := rpcplus.NewServer()
    {{range $key, $value := .Schema.Definitions}}
        {{$type := .Type}}
        {{/* export functions if they have any exported function */}}
        {{if len .Functions}}
            {{/* export functions if they are objects */}}
            {{if Equal $type "object"}}
                server.Register(new({{ToLower $Name}}api.{{$key}}))
            {{end}}
        {{end}}
    {{end}}

    rpcwrap.ServeCustomRPC(
        Mux,
        server,
        false,  // use auth
        "json", // codec name
        jsonrpc.NewServerCodec,
    )

    rpcwrap.ServeHTTPRPC(
        Mux,                    // httpmuxer
        server,                 // rpcserver
        "http_json",            // codec name
        jsonrpc.NewServerCodec, // jsoncodec
        ContextCreator,         // contextCreator
    )

    fmt.Println("Server listening on 3000")
    http.ListenAndServe("localhost:3000", Mux)
}`
