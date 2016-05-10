package publicip_test

import (
	"testing"

	"koding/klient/info/publicip"
)

func TestPublicIP(t *testing.T) {
	ip, err := publicip.PublicIP()
	if err != nil {
		t.Fatalf("PublicIP()=%s", err)
	}

	if ip == nil {
		t.Fatal("ip is nil")
	}

	t.Logf("public IP is %s", ip)
}
