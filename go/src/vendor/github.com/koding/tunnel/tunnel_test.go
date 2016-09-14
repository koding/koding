package tunnel_test

import (
	"fmt"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/koding/tunnel"
	"github.com/koding/tunnel/tunneltest"

	"github.com/cenkalti/backoff"
)

func TestMultipleRequest(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	// make a request to tunnelserver, this should be tunneled to local server
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := echoHTTP(tt, msg)
			if err != nil {
				t.Fatalf("echoHTTP error: %s", err)
			}

			if res != msg {
				t.Errorf("got %q, want %q", res, msg)
			}
		}(i)
	}

	wg.Wait()
}

func TestMultipleLatencyRequest(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerLatencyEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	// make a request to tunnelserver, this should be tunneled to local server
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := echoHTTP(tt, msg)
			if err != nil {
				t.Fatalf("echoHTTP error: %s", err)
			}

			if res != msg {
				t.Errorf("got %q, want %q", res, msg)
			}
		}(i)
	}

	wg.Wait()
}

func TestReconnectClient(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	msg := "hello"
	res, err := echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != msg {
		t.Errorf("got %q, want %q", res, msg)
	}

	client := tt.Clients["http"]

	// close client, and start it again
	client.Close()

	go client.Start()
	<-client.StartNotify()

	msg = "helloagain"
	res, err = echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != msg {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestNoClient(t *testing.T) {
	const expectedErr = "no client session established"

	rec := tunneltest.NewStateRecorder()

	tt, err := tunneltest.Serve(singleRecHTTP(handlerEchoHTTP, rec.C()))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	if err := rec.WaitTransitions(
		tunnel.ClientStarted,
		tunnel.ClientConnecting,
		tunnel.ClientConnected,
	); err != nil {
		t.Fatal(err)
	}

	if err := tt.ServerStateRecorder.WaitTransition(
		tunnel.ClientUnknown,
		tunnel.ClientConnected,
	); err != nil {
		t.Fatal(err)
	}

	// close client, this is the main point of the test
	if err := tt.Clients["http"].Close(); err != nil {
		t.Fatal(err)
	}

	if err := rec.WaitTransitions(
		tunnel.ClientConnected,
		tunnel.ClientDisconnected,
		tunnel.ClientClosed,
	); err != nil {
		t.Fatal(err)
	}

	if err := tt.ServerStateRecorder.WaitTransition(
		tunnel.ClientConnected,
		tunnel.ClientClosed,
	); err != nil {
		t.Fatal(err)
	}

	msg := "hello"
	res, err := echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != expectedErr {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestNoHost(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	noBackoff := backoff.NewConstantBackOff(time.Duration(-1))

	unknown, err := tunnel.NewClient(&tunnel.ClientConfig{
		Identifier: "unknown",
		ServerAddr: tt.ServerAddr().String(),
		Backoff:    noBackoff,
		Debug:      testing.Verbose(),
	})
	if err != nil {
		t.Fatalf("client error: %s", err)
	}
	unknown.Start()
	defer unknown.Close()

	if err := tt.ServerStateRecorder.WaitTransition(
		tunnel.ClientUnknown,
		tunnel.ClientClosed,
	); err != nil {
		t.Fatal(err)
	}

	unknown.Start()
	if err := tt.ServerStateRecorder.WaitTransition(
		tunnel.ClientClosed,
		tunnel.ClientClosed,
	); err != nil {
		t.Fatal(err)
	}
}

func TestNoLocalServer(t *testing.T) {
	const expectedErr = "no local server"

	tt, err := tunneltest.Serve(singleHTTP(handlerEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	// close local listener, this is the main point of the test
	tt.Listeners["http"][0].Close()

	msg := "hello"
	res, err := echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != expectedErr {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestSingleRequest(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	msg := "hello"
	res, err := echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != msg {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestSingleLatencyRequest(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(handlerLatencyEchoHTTP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	msg := "hello"
	res, err := echoHTTP(tt, msg)
	if err != nil {
		t.Fatalf("echoHTTP error: %s", err)
	}

	if res != msg {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestSingleTCP(t *testing.T) {
	tt, err := tunneltest.Serve(singleTCP(handlerEchoTCP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	msg := "hello"
	res, err := echoTCP(tt, msg)
	if err != nil {
		t.Fatalf("echoTCP error: %s", err)
	}

	if msg != res {
		t.Errorf("got %q, want %q", res, msg)
	}
}

func TestMultipleTCP(t *testing.T) {
	tt, err := tunneltest.Serve(singleTCP(handlerEchoTCP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := echoTCP(tt, msg)
			if err != nil {
				t.Errorf("echoTCP: %s", err)
			}

			if res != msg {
				t.Errorf("got %q, want %q", res, msg)
			}
		}(i)
	}

	wg.Wait()
}

func TestMultipleLatencyTCP(t *testing.T) {
	tt, err := tunneltest.Serve(singleTCP(handlerLatencyEchoTCP))
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			msg := "hello" + strconv.Itoa(i)
			res, err := echoTCP(tt, msg)
			if err != nil {
				t.Errorf("echoTCP: %s", err)
			}

			if res != msg {
				t.Errorf("got %q, want %q", res, msg)
			}
		}(i)
	}

	wg.Wait()
}

func TestMultipleStreamTCP(t *testing.T) {
	tunnels := map[string]*tunneltest.Tunnel{
		"http": {
			Type:      tunneltest.TypeHTTP,
			LocalAddr: "127.0.0.1:0",
			Handler:   handlerEchoHTTP,
		},
		"tcp": {
			Type:        tunneltest.TypeTCP,
			ClientIdent: "http",
			LocalAddr:   "127.0.0.1:0",
			RemoteAddr:  "127.0.0.1:0",
			Handler:     handlerEchoTCP,
		},
		"tcp_all": {
			Type:        tunneltest.TypeTCP,
			ClientIdent: "http",
			LocalAddr:   "127.0.0.1:0",
			RemoteAddr:  "0.0.0.0:0",
			Handler:     handlerEchoTCP,
		},
	}

	addrs, err := tunneltest.UsableAddrs()
	if err != nil {
		t.Fatal(err)
	}

	clients := []string{"tcp"}
	for i, addr := range addrs {
		if addr.IP.IsLoopback() {
			continue
		}

		client := fmt.Sprintf("tcp_%d", i)

		tunnels[client] = &tunneltest.Tunnel{
			Type:            tunneltest.TypeTCP,
			ClientIdent:     "http",
			LocalAddr:       "127.0.0.1:0",
			RemoteAddrIdent: "tcp_all",
			IP:              addr.IP,
			Handler:         handlerEchoTCP,
		}

		clients = append(clients, client)
	}

	tt, err := tunneltest.Serve(tunnels)
	if err != nil {
		t.Fatal(err)
	}
	defer tt.Close()

	var wg sync.WaitGroup
	for i := 0; i < 100/len(clients); i++ {
		wg.Add(len(clients))

		for j, ident := range clients {
			go func(ident string, i, j int) {
				defer wg.Done()
				msg := fmt.Sprintf("hello_%d_client_%d", j, i)
				res, err := echoTCPIdent(tt, msg, ident)
				if err != nil {
					t.Errorf("echoTCP: %s", err)
				}

				if res != msg {
					t.Errorf("got %q, want %q", res, msg)
				}
			}(ident, i, j)
		}
	}

	wg.Wait()
}
