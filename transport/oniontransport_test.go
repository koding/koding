package transport

import (
	"testing"
)

func TestOnionTransport(t *testing.T) {
	var _ Transport = (*OnionTransport)(nil)
}
