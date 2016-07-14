package sockjsclient

// http://sockjs.github.io/sockjs-protocol/sockjs-protocol-0.3.3.html

import (
	crand "crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

// Rand is a threaSafe rand.Rand type
type Rand struct {
	r *rand.Rand
	sync.Mutex
}

var r = Rand{
	r: rand.New(rand.NewSource(time.Now().UnixNano())),
}

// ErrSessionClosed is returned by Send/Recv methods when
// calling them after the session got closed.
var ErrSessionClosed = errors.New("session is closed")

// WebsocketSession represents a sockjs.Session over
// a websocket connection.
type WebsocketSession struct {
	conn     *websocket.Conn
	id       string
	messages []string
	closed   int32

	mu sync.Mutex // mu protects writes to conn
}

// DialOptions are used to overwrite default behavior
// of the websocket session.
type DialOptions struct {
	BaseURL string // required

	ReadBufferSize  int
	WriteBufferSize int
	Timeout         time.Duration
	ClientFunc      func(*DialOptions) *http.Client
}

// Client gives a client to use for making HTTP requests.
//
// If ClientFunc is non-nil it is used to make the requests.
// Otherwise default client is returned.
func (opts *DialOptions) Client() *http.Client {
	if opts.ClientFunc != nil {
		return opts.ClientFunc(opts)
	}

	return defaultClient(opts)
}

func defaultClient(opts *DialOptions) *http.Client {
	return &http.Client{
		// never make it less than the heartbeat delay from the sockjs server.
		// If this is los, your requests to the server will time out, so you'll
		// never receive the heartbeat frames.
		Timeout: opts.Timeout,
		// add this so we can make use of load balancer's sticky session features,
		// such as AWS ELB
		Jar: cookieJar,
	}
}

// ConnectWebsocketSession dials the remote specified in the opts and
// creates new websocket session.
func ConnectWebsocketSession(opts *DialOptions) (*WebsocketSession, error) {
	dialURL, err := url.Parse(opts.BaseURL)
	if err != nil {
		return nil, err
	}

	// will be used to set the origin header
	originalScheme := dialURL.Scheme

	if err := replaceSchemeWithWS(dialURL); err != nil {
		return nil, err
	}

	if err := addMissingPortAndSlash(dialURL); err != nil {
		return nil, err
	}

	serverID := threeDigits()
	sessionID := randomStringLength(20)

	// Add server_id and session_id to the path.
	dialURL.Path += serverID + "/" + sessionID + "/websocket"

	requestHeader := http.Header{}
	requestHeader.Add("Origin", originalScheme+"://"+dialURL.Host)

	ws := websocket.Dialer{
		ReadBufferSize:  opts.ReadBufferSize,
		WriteBufferSize: opts.WriteBufferSize,
	}

	// if the user passed a custom HTTP client and its transport
	// is of *http.Transport type - we're using its Dial field
	// for connecting to remote host
	if t, ok := opts.Client().Transport.(*http.Transport); ok {
		ws.NetDial = t.Dial
	}

	// if the user passed a timeout, use a dial with a timeout
	if opts.Timeout != 0 && ws.NetDial == nil {
		// If ws.NetDial is non-nil then gorilla does not
		// use ws.HandshakeTimeout for the deadlines.
		//
		// Instead we're going to set it ourselves.
		ws.NetDial = (&net.Dialer{
			Timeout:  opts.Timeout,
			Deadline: time.Now().Add(opts.Timeout),
		}).Dial
	}

	conn, _, err := ws.Dial(dialURL.String(), requestHeader)
	if err != nil {
		return nil, err
	}

	session := NewWebsocketSession(conn)
	session.id = sessionID
	return session, nil
}

// NewWebsocketSession creates new sockjs.Session from existing
// websocket connection.
func NewWebsocketSession(conn *websocket.Conn) *WebsocketSession {
	return &WebsocketSession{
		conn: conn,
	}
}

// RemoteAddr gives network address of the remote client.
func (w *WebsocketSession) RemoteAddr() string {
	return w.conn.RemoteAddr().String()
}

// ID returns a session id.
func (w *WebsocketSession) ID() string {
	return w.id
}

// Recv reads one text frame from session.
func (w *WebsocketSession) Recv() (string, error) {
	// Return previously received messages if there is any.
	if len(w.messages) > 0 {
		msg := w.messages[0]
		w.messages = w.messages[1:]
		return msg, nil
	}

read_frame:
	if atomic.LoadInt32(&w.closed) == 1 {
		return "", ErrSessionClosed
	}

	// Read one SockJS frame.
	_, buf, err := w.conn.ReadMessage()
	if err != nil {
		return "", err
	}

	if len(buf) == 0 {
		return "", errors.New("unexpected empty message")
	}

	frameType := buf[0]
	data := buf[1:]

	switch frameType {
	case 'o':
		// TODO handle open
		goto read_frame
	case 'a':
		var messages []string
		err = json.Unmarshal(data, &messages)
		if err != nil {
			return "", err
		}
		w.messages = append(w.messages, messages...)
	case 'm':
		var message string
		err = json.Unmarshal(data, &message)
		if err != nil {
			return "", err
		}
		w.messages = append(w.messages, message)
	case 'c':
		return "", errors.New("session closed")
	case 'h':
		// TODO handle heartbeat
		goto read_frame
	default:
		return "", errors.New("invalid frame type")
	}

	// Return first message in slice.
	if len(w.messages) == 0 {
		return "", errors.New("no message")
	}
	msg := w.messages[0]
	w.messages = w.messages[1:]
	return msg, nil
}

// Send sends one text frame to session
func (w *WebsocketSession) Send(str string) error {
	if atomic.LoadInt32(&w.closed) == 1 {
		return ErrSessionClosed
	}

	w.mu.Lock()
	defer w.mu.Unlock()

	b, _ := json.Marshal([]string{str})
	return w.conn.WriteMessage(websocket.TextMessage, b)
}

// Close closes the session with provided code and reason.
func (w *WebsocketSession) Close(uint32, string) error {
	if atomic.CompareAndSwapInt32(&w.closed, 0, 1) {
		return w.conn.Close()
	}

	return ErrSessionClosed
}

// threeDigits is used to generate a server_id.
func threeDigits() string {
	var i uint64

	r.Lock()
	i = uint64(r.r.Int31())
	r.Unlock()
	if i < 100 {
		i += 100
	}
	return strconv.FormatUint(i, 10)[:3]
}

// randomStringLength is used to generate a session_id.
func randomStringLength(length int) string {
	size := (length * 6 / 8) + 1
	r := make([]byte, size)
	crand.Read(r)
	return base64.URLEncoding.EncodeToString(r)[:length]
}

func replaceSchemeWithWS(u *url.URL) error {
	switch u.Scheme {
	case "http":
		u.Scheme = "ws"
	case "https":
		u.Scheme = "wss"
	default:
		return fmt.Errorf("invalid scheme in url: %s", u.Scheme)
	}
	return nil
}

// addMissingPortAndSlash appends 80 or 443 depending on the scheme
// if there is no port number in the URL.
// Also it adds "/" to the end of path if path does not ends with "/".
func addMissingPortAndSlash(u *url.URL) error {
	_, _, err := net.SplitHostPort(u.Host)
	if err != nil {
		if missingPortErr, ok := err.(*net.AddrError); ok && missingPortErr.Err == "missing port in address" {
			var port string
			switch u.Scheme {
			case "ws":
				port = "80"
			case "wss":
				port = "443"
			default:
				return fmt.Errorf("unknown scheme: %s", u.Scheme)
			}
			u.Host = net.JoinHostPort(strings.TrimRight(missingPortErr.Addr, ":"), port)
		} else {
			return err
		}
	}

	if u.Path == "" || u.Path[len(u.Path)-1:] != "/" {
		u.Path += "/"
	}

	return nil
}
