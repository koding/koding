package kloud

import (
	"testing"

	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/kloud/provider/digitalocean"
	"github.com/koding/kloud/provider/openstack"
)

func TestProviders(t *testing.T) {
	var _ protocol.Builder = &digitalocean.Provider{}
	var _ protocol.Builder = &amazon.Provider{}
	var _ protocol.Builder = &openstack.Provider{}
}
