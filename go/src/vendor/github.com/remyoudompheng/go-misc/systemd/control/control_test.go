package control

import (
	"bytes"
	"testing"

	dbus "github.com/remyoudompheng/go-dbus"
)

func TestList(t *testing.T) {
	bus, err := dbus.Connect(dbus.SystemBus)
	if err != nil {
		t.Fatal(err)
	}
	err = bus.Authenticate()
	if err != nil {
		t.Fatal(err)
	}

	out, err := ListUnits(bus)
	if err != nil {
		t.Fatal(err)
	}
	buf := new(bytes.Buffer)
	PrintUnits(buf, out)
	t.Logf("%s", buf)
}
