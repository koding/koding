package main

import (
	"fmt"
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
			addr, ok := args.(string)
			if !ok {
				return nil, &kite.ArgumentError{"string"}
			}

			conn, err := irc.NewConn(addr, log.RecoverAndLog)
			if err != nil {
				return nil, err
			}
			session.CloseOnDisconnect(conn)

			go func() {
				for message := range conn.ReceiveChannel {
					fmt.Println(message)
				}
			}()

			return conn, nil
		}

		return nil, &kite.UnknownMethodError{method}
	})
}
