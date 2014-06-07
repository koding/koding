// Package websocketproxy is a reverse proxy for WebSocket connections.
package websocketproxy

import (
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"

	"github.com/gorilla/websocket"
)

var (
	// DefaultUpgrader specifies the paramaters for upgrading an HTTP
	// connection to a WebSocket connection.
	DefaultUpgrader = &websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	// DefaultDialer is a dialer with all fields set to the default zero values.
	DefaultDialer = websocket.DefaultDialer
)

// WebsocketProxy is an HTTP Handler that takes an incoming websocket
// connection and proxies it to another server.
type WebsocketProxy struct {
	// Backend returns the backend URL which the proxy uses to reverse proxy
	// the incoming websocket connection. Request is the initial incoming and
	// unmodified request.
	Backend func(*http.Request) *url.URL

	// Upgrader specifies the paramaters for upgrading an HTTP connection to a
	// WebSocket connection. If nil, DefaultUpgrader is used.
	Upgrader *websocket.Upgrader

	//  Dialer contains options for connecting to WebSocket server. If nil,
	//  DefaultDialer is used.
	Dialer *websocket.Dialer
}

// ProxyHandler returns a new http.Handler interface that reverse proxies the
// request to the given target.
func ProxyHandler(target *url.URL) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		NewProxy(target).ServeHTTP(rw, req)
	})
}

// NewProxy returns a new Websocket reverse proxy that rewrites the
// URL's to the scheme, host and base path provider in target.
func NewProxy(target *url.URL) *WebsocketProxy {
	backend := func(r *http.Request) *url.URL { return target }
	return &WebsocketProxy{Backend: backend}
}

func (w *WebsocketProxy) CloseNotify() {
}

// ServeHTTP implements the http.Handler that proxies WebSocket connections.
func (w *WebsocketProxy) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	backendURL := w.Backend(req)

	dialer := w.Dialer
	if w.Dialer == nil {
		dialer = DefaultDialer
	}

	// Pass headers from the incoming request to the dialer to forward them to
	// the final destinations.
	h := http.Header{}
	h.Add("Origin", req.Header.Get("Origin"))
	protocols := req.Header["Sec-WebSocket-Protocol"]
	for _, prot := range protocols {
		h.Add("Sec-WebSocket-Protocol", prot)
	}
	cookies := req.Header["Cookie"]
	for _, cookie := range cookies {
		h.Add("Cookie", cookie)
	}

	// Pass X-Forwarded-For headers too, code below is a part of
	// httputil.ReverseProxy. See http://en.wikipedia.org/wiki/X-Forwarded-For
	// for more information
	if clientIP, _, err := net.SplitHostPort(req.RemoteAddr); err == nil {
		// If we aren't the first proxy retain prior
		// X-Forwarded-For information as a comma+space
		// separated list and fold multiple headers into one.
		if prior, ok := req.Header["X-Forwarded-For"]; ok {
			clientIP = strings.Join(prior, ", ") + ", " + clientIP
		}
		h.Set("X-Forwarded-For", clientIP)
	}

	// Set the originating protol of the incoming HTTP request. The SSL might
	// be terminated on our site and because we doing proxy adding this would
	// be helpful for applications on the backedn.
	h.Set("X-Forwarded-Proto", "http")
	if req.TLS != nil {
		h.Set("X-Forwarded-Proto", "https")
	}

	// Connect to the backend url, also pass the headers we prepared above.
	// TODO: support multiplexing on the same backend connection instead of
	// opening a new TCP connection time for each request.
	connBackend, resp, err := dialer.Dial(backendURL.String(), h)
	if err != nil {
		log.Printf("websocketproxy: couldn't dial to remote backend url %s\n", err)
		return
	}
	defer connBackend.Close()

	upgrader := w.Upgrader
	if w.Upgrader == nil {
		upgrader = DefaultUpgrader
	}

	// Only pass those headers to the upgrader.
	upgradeHeader := http.Header{}
	upgradeHeader.Add("Sec-WebSocket-Protocol", resp.Header.Get("Sec-WebSocket-Protocol"))
	upgradeHeader.Add("Set-Cookie", resp.Header.Get("Set-Cookie"))

	// Now upgrade the existing incoming request to a WebSocket connection.
	// Also pass the header that we gathered from the Dial handshake.
	connPub, err := upgrader.Upgrade(rw, req, upgradeHeader)
	if err != nil {
		log.Printf("websocketproxy: couldn't upgrade %s\n", err)
		return
	}
	defer connPub.Close()

	errc := make(chan error, 2)
	cp := func(dst io.Writer, src io.Reader) {
		_, err := io.Copy(dst, src)
		errc <- err
	}

	// Start our proxy now, everything is ready...
	go cp(connBackend.UnderlyingConn(), connPub.UnderlyingConn())
	go cp(connPub.UnderlyingConn(), connBackend.UnderlyingConn())
	<-errc
}
