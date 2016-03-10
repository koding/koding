package e2etest

import (
	"net/http"
	"net/url"
	"sync"
	"testing"
	"time"

	"koding/kites/kloud/utils"
	"koding/kites/tunnelproxy"
)

func TestE2E_Tunnelproxy(t *testing.T) {
	ktrl := NewKontrol()
	ktrl.Start()
	defer ktrl.Close()

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
		RegisterURL:     serverURL,
		Log:             Test.Log.New("tunnelserver"),
		Debug:           true,
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
	clientOpts := &tunnelproxy.ClientOptions{
		LastVirtualHost: serverURL.Host,
		LocalAddr:       host(localServer.URL),
		Config:          clientCfg,
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
