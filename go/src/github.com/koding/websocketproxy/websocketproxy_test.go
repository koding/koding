package websocketproxy

import (
	"log"
	"net/http"
	"net/url"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

var (
	serverURL  = "ws://127.0.0.1:7777"
	backendURL = "ws://127.0.0.1:8888"
)

func TestProxy(t *testing.T) {
	// websocket proxy
	upgrader := &websocket.Upgrader{
		ReadBufferSize:  4096,
		WriteBufferSize: 4096,
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}

	u, _ := url.Parse(backendURL)
	proxy := NewProxy(u)
	proxy.Upgrader = upgrader

	mux := http.NewServeMux()
	mux.Handle("/proxy", proxy)
	go func() {
		if err := http.ListenAndServe(":7777", mux); err != nil {
			t.Fatal("ListenAndServe: ", err)
		}
	}()

	time.Sleep(time.Millisecond * 100)

	// backend echo server
	go func() {
		mux2 := http.NewServeMux()
		mux2.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			conn, err := upgrader.Upgrade(w, r, nil)
			if err != nil {
				log.Println(err)
				return
			}

			messageType, p, err := conn.ReadMessage()
			if err != nil {
				return
			}

			if err = conn.WriteMessage(messageType, p); err != nil {
				return
			}
		})

		err := http.ListenAndServe(":8888", mux2)
		if err != nil {
			t.Fatal("ListenAndServe: ", err)
		}
	}()

	time.Sleep(time.Millisecond * 100)

	// frontend server, dial now our proxy, which will reverse proxy our
	// message to the backend websocket server.
	conn, _, err := websocket.DefaultDialer.Dial(serverURL+"/proxy", nil)
	if err != nil {
		t.Fatal(err)
	}

	msg := "hello kite"
	err = conn.WriteMessage(websocket.TextMessage, []byte(msg))
	if err != nil {
		t.Error(err)
	}

	messageType, p, err := conn.ReadMessage()
	if err != nil {
		t.Error(err)
	}

	if messageType != websocket.TextMessage {
		t.Error("incoming message type is not Text")
	}

	if msg != string(p) {
		t.Errorf("expecting: %s, got: %s", msg, string(p))
	}
}
