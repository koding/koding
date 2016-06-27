package vagrant_test

import (
	"errors"
	"reflect"
	"strings"
	"testing"

	"github.com/koding/logging"

	"koding/klient/vagrant"
)

func testExec(output map[string]string) func() {
	fn := func(cmd string, args ...string) ([]byte, error) {
		cmdLine := strings.TrimSpace(cmd + " " + strings.Join(args, " "))

		s, ok := output[cmdLine]
		if !ok {
			return nil, errors.New("unexpected command: " + cmdLine)
		}

		return []byte(s), nil
	}

	vagrant.SetTestExec(fn)
	return func() { vagrant.SetTestExec(nil) }
}

func TestVboxIsVagrant(t *testing.T) {
	cases := []struct {
		raw string
		ok  bool
	}{
		{vagrantLsmod, true}, // i=0
		{gceLsmod, false},    // i=1
	}

	for i, cas := range cases {
		output := map[string]string{
			"lsmod": cas.raw,
		}
		defer testExec(output)()

		ok, err := vagrant.VboxIsVagrant()
		if err != nil {
			t.Errorf("%d: IsVagrant()=%s", i, err)
			continue
		}

		if ok != cas.ok {
			t.Errorf("%d: got %t, want %t", i, ok, cas.ok)
		}
	}
}

var h = vagrant.NewHandlers(&vagrant.Options{Log: logging.NewCustom("vagrant", true)})

func TestVboxLookupName(t *testing.T) {
	output := map[string]string{
		"VBoxManage list vms": vboxManageList,
	}
	defer testExec(output)()

	want := "urfve6cb85a2_default_1458910687825_39001"

	got, err := h.VboxLookupName("urfve6cb85a2")
	if err != nil {
		t.Fatalf("VboxLookupName()=%s", err)
	}

	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
}

func TestVboxForwardedPorts(t *testing.T) {
	output := map[string]string{
		"VBoxManage showvminfo urfve6cb85a2_default_1458910687825_39001 --machinereadable": vboxManageShowvminfo,
	}
	defer testExec(output)()

	want := []*vagrant.ForwardedPort{{
		GuestPort: 22,
		HostPort:  2200,
	}, {
		GuestPort: 56789,
		HostPort:  2201,
	}, {
		GuestPort: 56787,
		HostPort:  2202,
	}}

	got, err := h.VboxForwardedPorts("urfve6cb85a2_default_1458910687825_39001")
	if err != nil {
		t.Fatalf("VboxForwardedPorts()=%s", err)
	}

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}
