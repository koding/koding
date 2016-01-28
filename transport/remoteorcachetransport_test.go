package transport

import (
	"testing"
)

func TestRemoteOrCacheTransport(t *testing.T) {
	var _ Transport = (*RemoteOrCacheTransport)(nil)
}
