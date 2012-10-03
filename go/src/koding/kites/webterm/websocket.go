package main

import (
	"code.google.com/p/go.net/websocket"
	"fmt"
	"koding/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"net/http"
)

func runWebsocket() {
	fmt.Println("WebSocket server started. Please open terminal.html in your browser.")
	http.Handle("/", websocket.Handler(func(ws *websocket.Conn) {
		fmt.Printf("WebSocket opened: %p\n", ws)

		server := &WebtermServer{session: kite.NewSession(config.Current.User)}
		defer server.Close()

		d := dnode.New()
		defer d.Close()
		d.SendRemote(server)
		d.OnRemote = func(remote dnode.Remote) {
			server.remote = remote
		}

		go func() {
			for data := range d.SendChan {
				websocket.Message.Send(ws, data)
			}
		}()

		for {
			var data []byte
			err := websocket.Message.Receive(ws, &data)
			if err != nil {
				break
			}
			d.ProcessMessage(data)
		}

		fmt.Printf("WebSocket closed: %p\n", ws)
	}))
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		panic(err)
	}
}
