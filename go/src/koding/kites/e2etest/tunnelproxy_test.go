package e2etest

import (
	"fmt"
	"net/http"
	"net/url"
	"sync"
	"testing"
	"time"

	"koding/kites/kloud/utils"
	"koding/kites/tunnelproxy"

	"github.com/koding/kite"
)

func TestE2E_TunnelproxyHTTP(t *testing.T) {
	testWithTunnelserver(t, testTunnelserverHTTP)
}

func TestE2E_TunnelproxyTCP(t *testing.T) {
	testWithTunnelserver(t, testTunnelserverTCP)
}

func testTunnelserverHTTP(t *testing.T, serverURL *url.URL) {
	// Create and start local server. All requests to this server are tunneled.
	received := make(chan *http.Request, 32)
	localServer := Test.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		received <- r
		w.WriteHeader(204)
	}))

	// Create and start Tunnel Client. It takes care of forwarding requests
	// from the internet to the loceal server.
	var virtualHost string
	var wg sync.WaitGroup
	wg.Add(1)
	clientCfg, _ := Test.GenKiteConfig()
	k := kite.New("tunnelclient", "0.0.1")
	k.Config = clientCfg
	clientOpts := &tunnelproxy.ClientOptions{
		LastVirtualHost: serverURL.Host,
		LocalAddr:       host(localServer.URL),
		Kite:            k,
		OnRegister: func(req *tunnelproxy.RegisterResult) {
			virtualHost = req.VirtualHost
			wg.Done()
		},
		Log:     Test.Log.New("tunnelclient"),
		Debug:   true,
		Timeout: 1 * time.Minute,
	}

	client, err := tunnelproxy.NewClient(clientOpts)
	if err != nil {
		t.Fatalf("error creating tunnelproxy client: %s", err)
	}

	client.Start()
	defer client.Close()
	wg.Wait()

	if virtualHost == "" {
		t.Fatal("expected virtualHost to be non-empty")
	}

	cases := []struct {
		Method string
		URL    *url.URL
	}{{ // i=0
		Method: "GET",
		URL: &url.URL{
			Scheme: "http",
			Host:   serverURL.Host,
			Path:   "/",
		},
	}, { // i=1
		Method: "GET",
		URL: &url.URL{
			Scheme: "http",
			Host:   serverURL.Host,
			Path:   "/foo",
		},
	}, { // i=2
		Method: "DELETE",
		URL: &url.URL{
			Scheme: "http",
			Host:   serverURL.Host,
			Path:   "/foo/bar",
		},
	}, { // i=3
		Method: "POST",
		URL: &url.URL{
			Scheme: "http",
			Host:   serverURL.Host,
			Path:   "/" + utils.RandString(32),
		},
	}, { // i=4
		Method: "PUT",
		URL: &url.URL{
			Scheme: "http",
			Host:   serverURL.Host,
			Path:   "/" + utils.RandString(32),
		},
	}}

	// Send requests to public end of the tunnel.
	for i, cas := range cases {
		req, err := http.NewRequest(cas.Method, cas.URL.String(), nil)
		if err != nil {
			t.Fatalf("%d: error creating request to %s: %s", i, cas.URL, err)
		}
		req.Host = virtualHost
		_, err = http.DefaultClient.Do(req)
		if err != nil {
			t.Fatalf("%d: error sending request to %s: %s", i, cas.URL, err)
		}
	}

	timeout := time.After(1 * time.Minute)

	// Ensure all the requests were forwarded.
	for i, cas := range cases {
		select {
		case req := <-received:
			if req.Method != cas.Method {
				t.Errorf("%d: want Method=%q; got %q", i, cas.Method, req.Method)
			}
			if req.URL.Path != cas.URL.Path {
				t.Errorf("%d: want Path=%q; got %q", i, cas.URL.Path, req.URL.Path)
			}
		case <-timeout:
			t.Fatalf("receiving requests from %s timed out", localServer.URL)
		}
	}
}

func testTunnelserverTCP(t *testing.T, serverURL *url.URL) {
	var (
		virtualHost string
		wg          sync.WaitGroup
		rec         = newServiceRecorder()
	)

	wg.Add(1)

	echo1, err := newEchoService()
	if err != nil {
		t.Fatalf("newEchoService()=%s", err)
	}
	defer echo1.Close()

	echo2, err := newEchoService()
	if err != nil {
		t.Fatalf("newEchoService()=%s", err)
	}
	defer echo1.Close()

	clientCfg, _ := Test.GenKiteConfig()
	k := kite.New("tunnelclient", "0.0.1")
	k.Config = clientCfg
	clientOpts := &tunnelproxy.ClientOptions{
		LastVirtualHost:    serverURL.Host,
		Kite:               k,
		OnRegisterServices: rec.Record,
		OnRegister: func(req *tunnelproxy.RegisterResult) {
			virtualHost = req.VirtualHost
			wg.Done()
		},
		Log:     Test.Log.New("tunnelclient"),
		Debug:   true,
		Timeout: 1 * time.Minute,
	}

	client, err := tunnelproxy.NewClient(clientOpts)
	if err != nil {
		t.Fatalf("error creating tunnelproxy client: %s", err)
	}

	client.Start()
	defer client.Close()
	wg.Wait()

	if virtualHost == "" {
		t.Fatal("expected virtualHost to be non-empty")
	}

	echo1service := &tunnelproxy.Service{
		Name:      "echo1",
		LocalAddr: echo1.Addr().String(),
	}

	if err := client.RegisterService(echo1service); err != nil {
		t.Fatalf("RegisterService(echo1)=%s", err)
	}

	echo2service := &tunnelproxy.Service{
		Name:      "echo2",
		LocalAddr: echo2.Addr().String(),
	}

	if err := client.RegisterService(echo2service); err != nil {
		t.Fatalf("RegisterService(echo2)=%s", err)
	}

	if err := rec.Wait("echo1", "echo2"); err != nil {
		t.Fatalf("Wait()=%s", err)
	}

	srv := rec.Services()
	rec.Clear()

	for _, service := range []string{"echo1", "echo2"} {
		client, err := dialTCP(srv[service].Port)
		if err != nil {
			t.Fatalf("%s: dialTCP()=%s", service, err)
		}

		for i := 0; i < 100; i++ {
			msg := fmt.Sprintf("hello_world_%d", i)
			client.out <- msg

			select {
			case <-time.After(tcpTimeout):
				t.Fatalf("%s(%d): timed out waiting for echo response to %q", service, i, msg)
			case resp := <-client.in:
				if resp != msg {
					t.Errorf("%s(%d): want %q, got %q", service, i, resp, msg)
				}
			}
		}

		client.Close()
	}

	// Close client to force disconnect. After connecting again, all TCP
	// services must be registered again.
	client.Close()
	wg.Add(1)
	client.Start()
	wg.Wait()

	if virtualHost == "" {
		t.Fatal("expected virtualHost to be non-empty")
	}

	if err := rec.Wait("echo1", "echo2"); err != nil {
		t.Fatalf("Wait()=%s", err)
	}
}

func testWithTunnelserver(t *testing.T, test func(*testing.T, *url.URL)) {
	// Create and start Tunnel Server.
	serverCfg, serverURL := Test.GenKiteConfig()
	if Test.NoPublic {
		// We start tunnel in a tunnel, so we can have more tunnels.
		n, err := NewNgrok()
		if err != nil {
			t.Fatalf("error creating ngrok tunnel: %s", err)
		}
		serverURL.Host, err = n.StartTCP(serverURL.Host)
		if err != nil {
			t.Fatalf("error starting ngrok tunnel: %s", err)
		}
		defer n.Stop()
	}

	baseHost := Test.HostedZone + ":" + port(serverURL.Host)
	Test.CleanRoute53 = append(Test.CleanRoute53, baseHost)

	serverOpts := &tunnelproxy.ServerOptions{
		BaseVirtualHost: baseHost,
		HostedZone:      Test.HostedZone,
		AccessKey:       Test.AccessKey,
		SecretKey:       Test.SecretKey,
		Config:          serverCfg,
		ServerAddr:      serverURL.Host,
		RegisterURL:     serverURL.String(),
		TCPRangeFrom:    10000,
		TCPRangeTo:      50000,
		Log:             Test.Log.New("tunnelserver"),
		Debug:           true,
		Test:            true,
	}

	server, err := tunnelproxy.NewServer(serverOpts)
	if err != nil {
		t.Fatalf("error creating tunnelproxy server: %s", err)
	}
	serverKite, err := tunnelproxy.NewServerKite(server, "tunnelkite", "0.0.1")
	if err != nil {
		t.Fatalf("error creating tunnelproxy server kite: %s", err)
	}
	defer serverKite.Close()

	go serverKite.Run()
	<-serverKite.ServerReadyNotify()

	test(t, serverURL)
}
