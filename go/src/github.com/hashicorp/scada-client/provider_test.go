package client

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/rpc"
	"reflect"
	"testing"
	"time"

	"github.com/hashicorp/net-rpc-msgpackrpc"
	"github.com/hashicorp/yamux"
)

func testProviderConfig() *ProviderConfig {
	return &ProviderConfig{
		Endpoint: "127.0.0.1:65500", // Blackhole
		Service: &ProviderService{
			Service:        "test",
			ServiceVersion: "v1.0",
			ResourceType:   "test",
			Capabilities:   make(map[string]int),
		},
		Handlers:      make(map[string]CapabilityProvider),
		ResourceGroup: "hashicorp/test",
		Token:         "abcdefg",
	}
}

func TestValidate(t *testing.T) {
	type tcase struct {
		valid bool
		inp   *ProviderConfig
	}
	tcases := []*tcase{
		&tcase{
			false,
			&ProviderConfig{},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{},
			},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{
					Service: "foo",
				},
			},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
				},
			},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
					ResourceType:   "foo",
				},
			},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
					ResourceType:   "foo",
				},
				ResourceGroup: "hashicorp/test",
			},
		},
		&tcase{
			true,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
					ResourceType:   "foo",
				},
				ResourceGroup: "hashicorp/test",
				Token:         "abcdefg",
			},
		},
		&tcase{
			false,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
					ResourceType:   "foo",
					Capabilities: map[string]int{
						"http": 1,
					},
				},
				ResourceGroup: "hashicorp/test",
				Token:         "abcdefg",
			},
		},
		&tcase{
			true,
			&ProviderConfig{
				Service: &ProviderService{
					Service:        "foo",
					ServiceVersion: "v1.0",
					ResourceType:   "foo",
					Capabilities: map[string]int{
						"http": 1,
					},
				},
				ResourceGroup: "hashicorp/test",
				Token:         "abcdefg",
				Handlers: map[string]CapabilityProvider{
					"http": nil,
				},
			},
		},
	}
	for idx, tc := range tcases {
		err := validateConfig(tc.inp)
		if (err == nil) != tc.valid {
			t.Fatalf("%d err: %v %v", idx, err, tc.inp)
		}
	}
}

func TestProvider_StartStop(t *testing.T) {
	p, err := NewProvider(testProviderConfig())
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if p.IsShutdown() {
		t.Fatalf("bad")
	}

	p.Shutdown()

	if !p.IsShutdown() {
		t.Fatalf("bad")
	}
}

func TestProvider_backoff(t *testing.T) {
	p, err := NewProvider(testProviderConfig())
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer p.Shutdown()

	if b := p.backoffDuration(); b != DefaultBackoff {
		t.Fatalf("bad: %v", b)
	}

	// Set a new minimum
	p.backoffLock.Lock()
	p.backoff = 60 * time.Second
	p.backoffLock.Unlock()

	if b := p.backoffDuration(); b != 60*time.Second {
		t.Fatalf("bad: %v", b)
	}

	// Set no retry
	p.backoffLock.Lock()
	p.noRetry = true
	p.backoffLock.Unlock()

	if b := p.backoffDuration(); b != 0 {
		t.Fatalf("bad: %v", b)
	}
}

func testTLSListener(t *testing.T) (string, net.Listener) {
	list, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	addr := fmt.Sprintf("127.0.0.1:%d", list.Addr().(*net.TCPAddr).Port)

	// Load the certificates
	cert, err := tls.LoadX509KeyPair("./test/cert.pem", "./test/key.pem")
	if err != nil {
		t.Fatalf("err: %v", err)
	}

	// Create the tls config
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
	}

	// TLS listener
	tlsList := tls.NewListener(list, tlsConfig)
	return addr, tlsList
}

type TestHandshake struct {
	t      *testing.T
	expect *HandshakeRequest
}

func (t *TestHandshake) Handshake(arg *HandshakeRequest, resp *HandshakeResponse) error {
	if !reflect.DeepEqual(arg, t.expect) {
		t.t.Fatalf("bad: %#v %#v", *arg, *t.expect)
	}
	resp.Authenticated = true
	resp.SessionID = "foobarbaz"
	return nil
}

func testHandshake(t *testing.T, list net.Listener, expect *HandshakeRequest) {
	client, err := list.Accept()
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer client.Close()

	preamble := make([]byte, len(clientPreamble))
	n, err := client.Read(preamble)
	if err != nil || n != len(preamble) {
		t.Fatalf("err: %v", err)
	}

	server, _ := yamux.Server(client, yamux.DefaultConfig())
	conn, err := server.Accept()
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer conn.Close()
	rpcCodec := msgpackrpc.NewCodec(true, true, conn)

	rpcSrv := rpc.NewServer()
	rpcSrv.RegisterName("Session", &TestHandshake{t, expect})

	err = rpcSrv.ServeRequest(rpcCodec)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
}

func TestProvider_Setup(t *testing.T) {
	addr, list := testTLSListener(t)
	defer list.Close()

	config := testProviderConfig()
	config.Endpoint = addr
	config.TLSConfig = &tls.Config{
		InsecureSkipVerify: true,
	}

	p, err := NewProvider(config)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer p.Shutdown()

	exp := &HandshakeRequest{
		Service:        "test",
		ServiceVersion: "v1.0",
		Capabilities:   make(map[string]int),
		Meta:           nil,
		ResourceType:   "test",
		ResourceGroup:  "hashicorp/test",
		Token:          "abcdefg",
	}
	testHandshake(t, list, exp)

	start := time.Now()
	for time.Now().Sub(start) < time.Second {
		if p.SessionID() != "" {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}

	if p.SessionID() != "foobarbaz" {
		t.Fatalf("bad: %v", p.SessionID())
	}
	if !p.SessionAuthenticated() {
		t.Fatalf("bad: %v", p.SessionAuthenticated())
	}
}

func fooCapability(t *testing.T) CapabilityProvider {
	return func(capa string, meta map[string]string, conn io.ReadWriteCloser) error {
		if capa != "foo" {
			t.Fatalf("bad: %s", capa)
		}
		if len(meta) != 1 || meta["zip"] != "zap" {
			t.Fatalf("bad: %s", meta)
		}
		_, err := conn.Write([]byte("foobarbaz"))
		if err != nil {
			return err
		}
		if err := conn.Close(); err != nil {
			return err
		}
		return nil
	}
}

func TestProvider_Connect(t *testing.T) {
	config := testProviderConfig()
	config.Service.Capabilities["foo"] = 1
	config.Handlers["foo"] = fooCapability(t)
	p, err := NewProvider(config)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer p.Shutdown()

	// Setup RPC client
	a, b := testConn(t)
	client, _ := yamux.Client(a, yamux.DefaultConfig())
	server, _ := yamux.Server(b, yamux.DefaultConfig())
	go p.handleSession(client, make(chan struct{}))

	stream, _ := server.Open()
	cc := msgpackrpc.NewCodec(false, false, stream)

	// Make the connect rpc
	args := &ConnectRequest{
		Capability: "foo",
		Meta: map[string]string{
			"zip": "zap",
		},
	}
	resp := &ConnectResponse{}
	err = msgpackrpc.CallWithCodec(cc, "Client.Connect", args, resp)
	if err != nil {
		t.Fatalf("err: %v", err)
	}

	// Should be successful!
	if !resp.Success {
		t.Fatalf("bad")
	}

	// At this point, we should be connected
	out := make([]byte, 9)
	n, err := stream.Read(out)
	if err != nil {
		t.Fatalf("err: %v %d", err, n)
	}

	if string(out) != "foobarbaz" {
		t.Fatalf("bad: %s", out)
	}
}

func TestProvider_Disconnect(t *testing.T) {
	config := testProviderConfig()
	p, err := NewProvider(config)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer p.Shutdown()

	// Setup RPC client
	a, b := testConn(t)
	client, _ := yamux.Client(a, yamux.DefaultConfig())
	server, _ := yamux.Server(b, yamux.DefaultConfig())
	go p.handleSession(client, make(chan struct{}))

	stream, _ := server.Open()
	cc := msgpackrpc.NewCodec(false, false, stream)

	// Make the connect rpc
	args := &DisconnectRequest{
		NoRetry: true,
		Backoff: 300 * time.Second,
	}
	resp := &DisconnectResponse{}
	err = msgpackrpc.CallWithCodec(cc, "Client.Disconnect", args, resp)
	if err != nil {
		t.Fatalf("err: %v", err)
	}

	p.backoffLock.Lock()
	defer p.backoffLock.Unlock()

	if p.backoff != 300*time.Second {
		t.Fatalf("bad: %v", p.backoff)
	}
	if !p.noRetry {
		t.Fatalf("bad")
	}

	p.sessionLock.Lock()
	defer p.sessionLock.Unlock()

	if p.sessionID != "" {
		t.Fatalf("Bad: %v", p.sessionID)
	}
	if p.sessionAuth {
		t.Fatalf("Bad: %v", p.sessionAuth)
	}
}

func TestProvider_Flash(t *testing.T) {
	config := testProviderConfig()
	buf := bytes.NewBuffer(nil)
	config.LogOutput = buf
	p, err := NewProvider(config)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	defer p.Shutdown()

	// Setup RPC client
	a, b := testConn(t)
	client, _ := yamux.Client(a, yamux.DefaultConfig())
	server, _ := yamux.Server(b, yamux.DefaultConfig())
	go p.handleSession(client, make(chan struct{}))

	stream, _ := server.Open()
	cc := msgpackrpc.NewCodec(false, false, stream)

	// Make the connect rpc
	args := &FlashRequest{
		Severity: "INFO",
		Message:  "TESTING",
	}
	resp := &FlashResponse{}
	err = msgpackrpc.CallWithCodec(cc, "Client.Flash", args, resp)
	if err != nil {
		t.Fatalf("err: %v", err)
	}

	// Wait until we are disconnected
	start := time.Now()
	for time.Now().Sub(start) < time.Second {
		if bytes.Contains(buf.Bytes(), []byte("TESTING")) {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	if !bytes.Contains(buf.Bytes(), []byte("TESTING")) {
		t.Fatalf("missing: %s", buf)
	}
}

func testConn(t *testing.T) (net.Conn, net.Conn) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	var serverConn net.Conn
	doneCh := make(chan struct{})
	go func() {
		defer close(doneCh)
		defer l.Close()
		var err error
		serverConn, err = l.Accept()
		if err != nil {
			t.Fatalf("err: %s", err)
		}
	}()

	clientConn, err := net.Dial("tcp", l.Addr().String())
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	<-doneCh

	return clientConn, serverConn
}
