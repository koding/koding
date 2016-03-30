package clients

// ClientsTemplate holds the template for the clients packages
var ClientsTemplate = `
{{$schema := .Schema}}
{{$title := $schema.Title}}

package {{ToLower .ModuleName}}client

import (
    "github.com/youtube/vitess/go/rpcplus"
    "golang.org/x/net/context"
)

// New creates a new local {{ToUpperFirst $title}} rpc client
func New{{ToUpperFirst $title}}(client *rpcplus.Client) *{{ToUpperFirst $title}} {
    return &{{ToUpperFirst $title}}{
        client: client,
    }
}

// {{ToUpperFirst $title}} is for holding the api functions
type {{ToUpperFirst $title}} struct{
    client *rpcplus.Client
}


{{range $funcKey, $funcValue := $schema.Functions}}
func ({{Pointerize $title}} *{{$title}}) {{$funcKey}}(ctx context.Context, req *{{Argumentize $funcValue.Properties.incoming}}, res *{{Argumentize $funcValue.Properties.outgoing}}) error {
    return {{Pointerize $title}}.client.Call(ctx, "{{ToUpperFirst $title}}.{{$funcKey}}", req, res)
}
{{end}}
`
