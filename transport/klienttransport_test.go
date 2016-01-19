package transport

import "testing"

func TestKlientTransport(t *testing.T) {
	var _ Transport = (*KlientTransport)(nil)
}
