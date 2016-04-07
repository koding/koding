package kit

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateTransportHTTPSemiotics generates HTTP transport's semiotics
func GenerateTransportHTTPSemiotics(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	return generate(context, s, TransportHTTPSemioticsTemplate, "transport_http_semiotics")
}
