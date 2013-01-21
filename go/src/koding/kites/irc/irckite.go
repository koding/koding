package main

import (
	"koding/tools/dnode"
	"koding/tools/irc"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/tools/utils"
)

func main() {
	utils.Startup("irc kite", false)

	k := kite.New("irc")
	k.Handle("connect", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Host      string         `json:"host"`
			OnMessage dnode.Callback `json:"onMessage"`
		}
		if args.Unmarshal(&params) != nil || params.Host == "" || params.OnMessage == nil {
			return nil, &kite.ArgumentError{"{ host: [string], onMessage: [function] }"}
		}

		conn, err := irc.NewConn(params.Host, log.RecoverAndLog)
		if err != nil {
			return nil, err
		}
		session.CloseOnDisconnect(conn)

		go func() {
			for message := range conn.ReceiveChannel {
				params.OnMessage(message)
			}
		}()

		return conn, nil
	})
	k.Run()
}
