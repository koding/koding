package kit

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateTransportHTTPServer generates HTTP transport's server 
func GenerateTransportHTTPServer(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	return generate(context, s, TransportHTTPServerTemplate, "transport_http_server")
}
