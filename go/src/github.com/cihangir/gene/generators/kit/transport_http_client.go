package kit

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateTransportHTTPClient generates HTTP transport's client
func GenerateTransportHTTPClient(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	return generate(context, s, TransportHTTPClientTemplate, "transport_http_client")
}
