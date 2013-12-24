package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tools/config"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"unsafe"

	"code.google.com/p/go.net/websocket"
)

type TLSKite struct {
	kite *kite.Kite

	tlsPort     int
	tlsListener net.Listener

	// Holds registered kites.
	urls map[*kite.RemoteKite]protocol.KiteURL
}

func main() {
	const port = 8443 // https-alt
	New(port).Run()
}

func New(tlsPort int) *TLSKite {
	options := &kite.Options{
		Kitename:    "tls",
		Version:     "0.0.1",
		Environment: "production",
		Region:      "localhost",
		Visibility:  protocol.Public,
	}

	tlsKite := &TLSKite{
		kite:    kite.New(options),
		tlsPort: tlsPort,
		urls:    make(map[*kite.RemoteKite]protocol.KiteURL),
	}

	tlsKite.kite.HandleFunc("register", tlsKite.register)

	// Remove URL from the map when Kite disconnects.
	tlsKite.kite.OnDisconnect(func(r *kite.RemoteKite) { delete(tlsKite.urls, r) })

	return tlsKite
}

func (t *TLSKite) Run() {
	t.startHTTPSServer()
	t.kite.Run()
}

func (t *TLSKite) Start() {
	t.startHTTPSServer()
	t.kite.Start()
}

func (t *TLSKite) startHTTPSServer() {
	srv := &websocket.Server{Handler: t.handleWS}
	srv.Config.TlsConfig = &tls.Config{}

	cert, err := tls.LoadX509KeyPair(config.Current.TLSKite.CertFile, config.Current.TLSKite.KeyFile)
	if err != nil {
		t.kite.Log.Fatal(err.Error())
	}

	srv.Config.TlsConfig.Certificates = []tls.Certificate{cert}

	addr := ":" + strconv.Itoa(t.tlsPort)
	t.tlsListener, err = net.Listen("tcp", addr)
	if err != nil {
		t.kite.Log.Fatal(err.Error())
	}

	t.tlsListener = tls.NewListener(t.tlsListener, srv.Config.TlsConfig)

	go func() {
		if err := http.Serve(t.tlsListener, srv); err != nil {
			t.kite.Log.Fatal(err.Error())
		}
	}()
}

func (t *TLSKite) register(r *kite.Request) (interface{}, error) {
	t.urls[r.RemoteKite] = r.RemoteKite.URL

	result := url.URL{
		Scheme: "wss",
		Host:   net.JoinHostPort(config.Current.TLSKite.Domain, strconv.Itoa(t.tlsPort)),
		Path:   fmt.Sprintf("/%d", unsafe.Pointer(r.RemoteKite)),
	}

	return result.String(), nil
}

func (t *TLSKite) handleWS(ws *websocket.Conn) {
	s := ws.Request().URL.Path[1:] // strip leading '/'
	i, err := strconv.ParseUint(s, 10, 64)
	if err != nil {
		return
	}

	r := (*kite.RemoteKite)(unsafe.Pointer(uintptr(i)))
	kiteURL, ok := t.urls[r]
	if !ok {
		return
	}

	conn, err := websocket.Dial(kiteURL.String(), "kite", "http://localhost")
	if err != nil {
		return
	}

	errc := make(chan error, 2)
	cp := func(dst io.Writer, src io.Reader) {
		_, err := io.Copy(dst, src)
		errc <- err
	}
	go cp(conn, ws)
	go cp(ws, conn)
	<-errc
}
