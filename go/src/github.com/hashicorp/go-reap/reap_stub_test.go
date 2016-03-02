// +build windows solaris

package reap

import (
	"runtime"
	"testing"
)

func TestReap_IsSupported(t *testing.T) {
	if IsSupported() {
		t.Fatalf("reap should not be supported on %s", runtime.GOOS)
	}
}

func TestReap_ReapChildren(t *testing.T) {
	pids := make(PidCh, 1)
	errors := make(ErrorCh, 1)
	ReapChildren(pids, errors, nil, nil)
	select {
	case <-pids:
		t.Fatalf("should not report any pids")
	case <-errors:
		t.Fatalf("should not report any errors")
	default:
	}
}
