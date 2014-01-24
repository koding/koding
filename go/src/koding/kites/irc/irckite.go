package main

import (
	"koding/tools/dnode"
	"koding/tools/irc"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/logger"
)

var log = logger.New("irckite")

func main() {
	lifecycle.Startup("kite.irc", false)

	k := kite.New("irc", false)
	k.Handle("connect", false, func(args *dnode.Partial, channel *kite.Channel) (interface{}, error) {
		var params struct {
			Host      string         `json:"host"`
			OnMessage dnode.Callback `json:"onMessage"`
		}
		if args.Unmarshal(&params) != nil || params.Host == "" || params.OnMessage == nil {
			return nil, &kite.ArgumentError{Expected: "{ host: [string], onMessage: [function] }"}
		}

		conn, err := irc.NewConn(params.Host, log.RecoverAndLog)
		if err != nil {
			return nil, err
		}
		channel.OnDisconnect(func() { conn.Close() })

		go func() {
			for message := range conn.ReceiveChannel {
				params.OnMessage(message)
			}
		}()

		return conn, nil
	})
	k.Run()
}
