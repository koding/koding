package machinegroup

import (
	"io/ioutil"
	"os"
	"os/user"
	"strconv"
	"testing"
	"time"

	"koding/kites/tunnelproxy/discover/discovertest"
	"koding/klient/machine"
	"koding/klient/machine/client/clienttest"
)

func TestSSH(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	wd, err := ioutil.TempDir("", "ssh")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Create test machine with IP address.
	const fakeHost = "127.0.32.123"
	createReq := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			id: {
				clienttest.TurnOnAddr(),
				machine.Addr{
					Network:   "ip",
					Value:     fakeHost,
					UpdatedAt: time.Now(),
				},
			},
		},
	}
	if _, err := g.Create(createReq); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Get SSH data from machine.
	sshReq := &SSHRequest{
		ID: id,
	}
	sshRes, err := g.SSH(sshReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	u, err := user.Current()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if sshRes.Username != u.Username {
		t.Errorf("want username = %q; got %q", u.Username, sshRes.Username)
	}

	if sshRes.Host != fakeHost {
		t.Errorf("want host address = %q; got %q", fakeHost, sshRes.Host)
	}

	if sshRes.Port != 0 {
		t.Errorf("want port = 0; got %d", sshRes.Port)
	}
}

func TestSSHDiscover(t *testing.T) {
	var (
		builder = clienttest.NewBuilder(nil)
		id      = machine.ID("serv")
	)

	// Create discover testing server. Local address will be preferred.
	const (
		fakeDiscoverHost = "127.0.0.1"
		fakeDiscoverPort = 5678
	)
	srv := discovertest.Server{
		"ssh": {{
			Addr:  fakeDiscoverHost + ":" + strconv.Itoa(fakeDiscoverPort),
			Local: true,
		}, {
			Addr:  "orange.user.kiwi.koding.me:1234",
			Local: false,
		}},
	}
	l, err := srv.Start()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer l.Close()

	wd, err := ioutil.TempDir("", "ssh")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(wd)

	g, err := New(testOptions(wd, builder))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer g.Close()

	// Create test machine with tunnel and IP addresses.
	createReq := &CreateRequest{
		Addresses: map[machine.ID][]machine.Addr{
			id: {
				clienttest.TurnOnAddr(),
				machine.Addr{
					Network:   "tunnel",
					Value:     l.Addr().String(),
					UpdatedAt: time.Now(),
				},
				machine.Addr{
					Network:   "ip",
					Value:     "53.23.123.4",
					UpdatedAt: time.Now(),
				},
			},
		},
	}
	if _, err := g.Create(createReq); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	if err := builder.WaitForBuild(time.Second); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	// Get SSH data from machine.
	const testUser = "testUser"
	sshReq := &SSHRequest{
		ID:       id,
		Username: testUser,
	}
	sshRes, err := g.SSH(sshReq)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if sshRes.Username != testUser {
		t.Errorf("want username = %q; got %q", testUser, sshRes.Username)
	}

	if sshRes.Host != fakeDiscoverHost {
		t.Errorf("want host address = %q; got %q", fakeDiscoverHost, sshRes.Host)
	}

	if sshRes.Port != fakeDiscoverPort {
		t.Errorf("want port = %d; got %d", fakeDiscoverPort, sshRes.Port)
	}
}
