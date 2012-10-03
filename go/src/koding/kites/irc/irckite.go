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

	kite.Run("irc", func(session *kite.Session, method string, args interface{}) (interface{}, error) {
		switch method {
		case "connect":
			argMap, ok1 := args.(map[string]interface{})
			host, ok2 := argMap["host"].(string)
			onMessage, ok3 := argMap["onMessage"].(dnode.Callback)
			if !ok1 || !ok2 || !ok3 {
				return nil, &kite.ArgumentError{"{ host: [string], onMessage: [function] }"}
			}

			conn, err := irc.NewConn(host, log.RecoverAndLog)
			if err != nil {
				return nil, err
			}
			session.CloseOnDisconnect(conn)

			go func() {
				for message := range conn.ReceiveChannel {
					onMessage(message)
				}
			}()

			return conn, nil
		}

		return nil, &kite.UnknownMethodError{method}
	})
}
