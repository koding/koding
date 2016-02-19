package transport

import "testing"

func TestRemoteTransport(t *testing.T) {
	var _ Transport = (*RemoteTransport)(nil)
}
