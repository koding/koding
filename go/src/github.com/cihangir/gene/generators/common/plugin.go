package common

import (
	"net/rpc"

	"github.com/hashicorp/go-plugin"
)


// HandshakeConfig is the contract between rpc plugin clients and servers.
var HandshakeConfig = plugin.HandshakeConfig{
	ProtocolVersion:  1,
	MagicCookieKey:   "GENE_PLUGIN",
	MagicCookieValue: "gene-cookie",
}

// GeneratorRPCServer provides rpc server functionality.
type GeneratorRPCServer struct{ Impl Generator }

// Generate implements generator interface.
func (g *GeneratorRPCServer) Generate(req *Req, res *Res) error {
	return g.Impl.Generate(req, res)
}

// GeneratorRPCClient provides rpc client functionality.
type GeneratorRPCClient struct{ Client *rpc.Client }

// Generate implements generator interface.
func (g *GeneratorRPCClient) Generate(req *Req, res *Res) error {
	return g.Client.Call("Plugin.Generate", req, res)
}

// GeneratorPlugin provides basic plugin system
type GeneratorPlugin struct{ generator Generator }

// NewGeneratorPlugin creates a new plugin out of given Generator
func NewGeneratorPlugin(g Generator) *GeneratorPlugin {
	return &GeneratorPlugin{generator: g}
}

// Server provides server functionality for plugins
func (g *GeneratorPlugin) Server(*plugin.MuxBroker) (interface{}, error) {
	return &GeneratorRPCServer{Impl: g.generator}, nil
}

// Client provides client functionality for plugins
func (g *GeneratorPlugin) Client(b *plugin.MuxBroker, c *rpc.Client) (interface{}, error) {
	return &GeneratorRPCClient{Client: c}, nil
}
