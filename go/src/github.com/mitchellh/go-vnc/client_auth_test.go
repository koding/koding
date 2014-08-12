package vnc

import "testing"

func TestClientAuthNone_Impl(t *testing.T) {
	var raw interface{}
	raw = new(ClientAuthNone)
	if _, ok := raw.(ClientAuth); !ok {
		t.Fatal("ClientAuthNone doesn't implement ClientAuth")
	}
}
