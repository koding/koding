package kite

import (
	"koding/tools/dnode"
	"koding/tools/log"
	"strings"
	"time"
)

func Start(uri, name string, onRootMethod func(user, method string, args interface{}) interface{}) {
	RunStatusLogger()

	for {
		func() {
			defer time.Sleep(10 * time.Second)
			defer log.RecoverAndLog()

			log.Info("Connecting to AMQP server...")

			consumeConn := createConn(uri)
			defer consumeConn.Close()

			publishConn := createConn(uri)
			defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			joinStream, joinChannel := declareBindConsumeQueue(consumeConn, "kite-"+name, "join", "private-kite-"+name)
			defer joinChannel.Close()

			for join := range joinStream {
				go func() {
					defer log.RecoverAndLog()

					secretName := string(join.Body)
					user := strings.Split(secretName, ".")[1]

					changeNumClients <- 1
					log.Debug("Client connected: " + user)

					defer func() {
						changeNumClients <- -1
						log.Debug("Client disconnected: " + user)
					}()

					messageStream, messageChannel := declareBindConsumeQueue(consumeConn, "", "client-message.*", secretName)
					defer messageChannel.Close()

					publishChannel := createChannel(consumeConn)
					defer publishChannel.Close()

					node := dnode.New(&connection{messageStream, publishChannel, secretName, "", make([]byte, 0)})
					node.OnRootMethod = func(method string, args []interface{}) {
						result := onRootMethod(user, method, args[0].(map[string]interface{})["withArgs"])
						if result != nil {
							args[1].(dnode.Callback)(result)
						}
					}
					node.Run()
				}()
			}

			log.Warn("Connection to AMQP server lost.")
		}()
	}
}
