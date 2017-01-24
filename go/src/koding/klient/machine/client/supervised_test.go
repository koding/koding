package client_test

import (
	"testing"
	"time"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
)

func TestSupervisedWait(t *testing.T) {
	serv := &clienttest.Server{}

	dc, err := client.NewDynamic(clienttest.DynamicOpts(serv, clienttest.NewBuilder(nil)))
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer dc.Close()

	dcf := func() (client.Client, error) { return dc.Client(), nil }

	// Server is off, so the timeout should be reached.
	const timeout = 50 * time.Millisecond
	spv := client.NewSupervised(dcf, timeout)
	startC, hitC := make(chan struct{}), make(chan time.Time)

	go func() {
		<-startC
		_, err = spv.CurrentUser()
		hitC <- time.Now()
	}()

	now := time.Now()
	close(startC)
	select {
	case called := <-hitC:
		if tret := called.Sub(now); tret < timeout {
			t.Fatalf("want return at least after %v; got %v", timeout, tret)
		}
		if err != client.ErrDisconnected {
			t.Fatalf("want err = %v; got %v", client.ErrDisconnected, err)
		}
	case <-time.After(time.Second):
		t.Fatalf("test timed out after 1s")
	}

	// Server starts to be responsive while Supervisor waits for it.
	spv = client.NewSupervised(dcf, 2*time.Second)
	startC, hitC = make(chan struct{}), make(chan time.Time)

	go func() {
		<-startC
		_, err = spv.CurrentUser()
		hitC <- time.Now()
	}()

	close(startC)
	serv.TurnOn()
	select {
	case <-hitC:
		if err == client.ErrDisconnected {
			t.Fatal("want err != client.ErrDisconnected")
		}
	case <-time.After(time.Second):
		t.Fatalf("test timed out after 1s")
	}
}
