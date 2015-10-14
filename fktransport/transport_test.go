package fktransport

import (
	"testing"
)

func TestTransportImplementations(t *testing.T) {
	var (
		_ Transport = (*fakeTransport)(nil)
		_ Transport = (*KlientTransport)(nil)
	)
}
