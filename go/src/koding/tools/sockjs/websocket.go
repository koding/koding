package sockjs

import (
	"net/http"
	"strings"

	"golang.org/x/net/websocket"
)

func (service *Service) serveWebsocket(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Connection", "Close")
	if !service.Websocket {
		http.NotFound(w, r)
		return
	}
	if r.Method != "GET" {
		w.Header().Set("Allow", "GET")
		w.WriteHeader(http.StatusMethodNotAllowed)
		conn, buf, _ := w.(http.Hijacker).Hijack()
		buf.Write([]byte("\r\n0\r\n\r\n"))
		buf.Flush()
		conn.Close()
		return
	}
	if !strings.EqualFold(r.Header.Get("Upgrade"), "WebSocket") {
		http.Error(w, `Can "Upgrade" only to "WebSocket".`, http.StatusBadRequest)
		return
	}
	if !strings.EqualFold(r.Header.Get("Connection"), "Upgrade") {
		http.Error(w, `"Connection" must be "Upgrade".`, http.StatusBadRequest)
		return
	}

	websocket.Handler(func(ws *websocket.Conn) {
		session := service.newSession(true) // websockets use completely independent sessions
		defer session.Close()

		go func() {
			var frame []byte
			closed := false
			for !closed {
				frame, closed = session.CreateNextFrame(nil, nil, false)
				WebsocketCodec.Send(ws, frame)
			}
			ws.Close()
		}()

		for {
			var data []byte
			err := WebsocketCodec.Receive(ws, &data)
			if err != nil {
				break
			}
			if len(data) != 0 {
				if !session.ReadMessages(data) {
					ws.Close()
					break
				}
			}
		}
	}).ServeHTTP(w, r)
}

func (service *Service) serveRawWebsocket(w http.ResponseWriter, r *http.Request) {
	if !service.Websocket {
		http.NotFound(w, r)
		return
	}
	websocket.Handler(func(ws *websocket.Conn) {
		receiveChan := make(chan interface{})
		defer close(receiveChan)

		sendChan := make(chan interface{})
		go func() {
			service.Callback(&Session{ReceiveChan: receiveChan, sendChan: sendChan})
			close(sendChan)
		}()

		go func() {
			for message := range sendChan {
				websocket.Message.Send(ws, message)
			}
			ws.Close()
		}()

		for {
			var message string
			err := websocket.Message.Receive(ws, &message)
			if err != nil {
				break
			}
			receiveChan <- message
		}
	}).ServeHTTP(w, r)
}

func marshal(v interface{}) (msg []byte, payloadType byte, err error) {
	return v.([]byte), websocket.TextFrame, nil
}

func unmarshal(msg []byte, payloadType byte, v interface{}) (err error) {
	*v.(*[]byte) = msg
	return nil
}

var WebsocketCodec = websocket.Codec{Marshal: marshal, Unmarshal: unmarshal}
