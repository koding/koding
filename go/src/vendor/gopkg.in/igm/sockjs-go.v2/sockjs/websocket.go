package sockjs

import (
	"net/http"

	"github.com/gorilla/websocket"
)

// WebSocketReadBufSize is a parameter that is used for WebSocket Upgrader.
// https://github.com/gorilla/websocket/blob/master/server.go#L230
//
// Deprecated: Set WebSocketUpgrader.ReadBufferSize instead.
var WebSocketReadBufSize = 4096

// WebSocketWriteBufSize is a parameter that is used for WebSocket Upgrader
// https://github.com/gorilla/websocket/blob/master/server.go#L230
//
// Deprecated: Set WebSocketUpgrader.WriteBufferSize instead.
var WebSocketWriteBufSize = 4096

// WebSocketUpgrader is used to configure websocket handshakes and websocket
// connection details.
var WebSocketUpgrader = &websocket.Upgrader{
	ReadBufferSize:  0,                                                       // reuses HTTP server's buffers
	WriteBufferSize: 0,                                                       // reuses HTTP server's buffers
	Error:           func(http.ResponseWriter, *http.Request, int, error) {}, // don't return errors to maintain backwards compatibility
	CheckOrigin:     func(*http.Request) bool { return true },                // allow all connections by default
}

func (h *handler) sockjsWebsocket(rw http.ResponseWriter, req *http.Request) {
	conn, err := WebSocketUpgrader.Upgrade(rw, req, nil)
	if _, ok := err.(websocket.HandshakeError); ok {
		http.Error(rw, `Can "Upgrade" only to "WebSocket".`, http.StatusBadRequest)
		return
	} else if err != nil {
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}
	sessID, _ := h.parseSessionID(req.URL)
	sess := newSession(req, sessID, h.options.DisconnectDelay, h.options.HeartbeatDelay)
	if h.handlerFunc != nil {
		go h.handlerFunc(sess)
	}

	receiver := newWsReceiver(conn)
	sess.attachReceiver(receiver)
	readCloseCh := make(chan struct{})
	go func() {
		var d []string
		for {
			err := conn.ReadJSON(&d)
			if err != nil {
				close(readCloseCh)
				return
			}
			sess.accept(d...)
		}
	}()

	select {
	case <-readCloseCh:
	case <-receiver.doneNotify():
	}
	sess.close()
	conn.Close()
}

type wsReceiver struct {
	conn    *websocket.Conn
	closeCh chan struct{}
}

func newWsReceiver(conn *websocket.Conn) *wsReceiver {
	return &wsReceiver{
		conn:    conn,
		closeCh: make(chan struct{}),
	}
}

func (w *wsReceiver) sendBulk(messages ...string) {
	if f := frame(messages); f != "" {
		w.sendFrame(f)
	}
}

func (w *wsReceiver) sendFrame(frame string) {
	if err := w.conn.WriteMessage(websocket.TextMessage, []byte(frame)); err != nil {
		w.close()
	}
}

func (w *wsReceiver) close() {
	select {
	case <-w.closeCh: // already closed
	default:
		close(w.closeCh)
	}
}
func (w *wsReceiver) canSend() bool {
	select {
	case <-w.closeCh: // already closed
		return false
	default:
		return true
	}
}
func (w *wsReceiver) doneNotify() <-chan struct{}        { return w.closeCh }
func (w *wsReceiver) interruptedNotify() <-chan struct{} { return nil }
