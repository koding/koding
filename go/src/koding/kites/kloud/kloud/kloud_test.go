package kloud

import (
	"testing"

	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"
	"koding/kites/kloud/provider/digitalocean"
	"koding/kites/kloud/provider/openstack"
)

func TestProviders(t *testing.T) {
	var _ protocol.Builder = &digitalocean.Provider{}
	var _ protocol.Builder = &amazon.Provider{}
	var _ protocol.Builder = &openstack.Provider{}
}
