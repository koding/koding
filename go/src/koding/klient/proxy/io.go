package proxy

import (
    "fmt"
    "time"

    "github.com/gorilla/websocket"
)

const (
    writeTime       = time.Second * 10
    pongTime        = time.Second * 60
    pingInterval    = (pongTime * 9) / 10
)

type WebsocketProxy struct {
    In      chan []byte
    Out     chan []byte
    conn    *websocket.Conn
}

func New(conn *websocket.Conn) *WebsocketProxy {
    return &WebsocketProxy{
        In:     make(chan []byte),
        Out:    make(chan []byte),
        conn:   conn,
    }
}

func (p *WebsocketProxy) PumpWrites() {
    ticker := time.NewTicker(pingInterval)
    defer ticker.Stop()

    defer fmt.Println("Exiting ingress websocket proxy routine.")

    for {
        select {
        case message, ok := <- p.In:
            p.conn.SetWriteDeadline(time.Now().Add(writeTime))

            if !ok {
                fmt.Println("Websocket proxy In channel was closed.")
                p.conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            if err := p.conn.WriteMessage(websocket.TextMessage, message); err != nil {
                fmt.Println("Failed to write message to websocket:", err)
                return
            }
        case <- ticker.C:
            p.conn.SetWriteDeadline(time.Now().Add(writeTime))

            if err := p.conn.WriteMessage(websocket.PingMessage, []byte{}); err != nil {
                fmt.Println("Failed to write ping message to websocket:", err)
                return
            }
        }
    }
}

func (p *WebsocketProxy) PumpReads() {
    defer fmt.Println("Exiting egress websocket proxy routine.")

    p.conn.SetReadDeadline(time.Now().Add(pongTime))

    defaultPongHandler := p.conn.PongHandler()
    p.conn.SetPongHandler(func (appData string) error {
        p.conn.SetReadDeadline(time.Now().Add(pongTime))

        return defaultPongHandler(appData)
    })

    for {
        t, message, err := p.conn.ReadMessage()
        fmt.Println("type:", t, "message:", message)

        if err != nil {
            fmt.Println("Failed to read from websocket:", err)
            break
        }

        p.Out <- message
    }
}
