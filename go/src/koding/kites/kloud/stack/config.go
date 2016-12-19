package stack

import (
	"koding/kites/config"

	"github.com/koding/kite"
)

// Metadata represents Koding configuration.
type Metadata struct {
	Endpoints *config.Endpoints `json:"endpoints"` // Koding endpoints
}

// ConfigMetadataRequest represents a request model for "config.metadata"
// kloud's kite method.
type ConfigMetadataRequest struct{}

// ConfigMetadataResponse represents a response model for "config.metadata"
// kloud's kite method.
type ConfigMetadataResponse struct {
	Metadata *Metadata `json:"metadata"`
}

// ConfigMetadata returns Koding metadata, used mainly by kd and klient.
//
// Previously Koding metadata was statically embedded into klient binaries,
// right now it's obtained dynamically during runtime via this call.
func (k *Kloud) ConfigMetadata(r *kite.Request) (interface{}, error) {
	return &ConfigMetadataResponse{
		Metadata: &Metadata{
			Endpoints: k.Endpoints,
		},
	}, nil
}
