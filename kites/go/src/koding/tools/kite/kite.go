package kite

import (
	"koding/tools/dnode"
	"koding/tools/log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

func Start(uri, name string, onRootMethod func(user, method string, args interface{}) interface{}) {
	runStatusLogger()

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	for !shutdown {
		func() {
			defer time.Sleep(10 * time.Second)
			defer log.RecoverAndLog()

			log.Info("Connecting to AMQP server...")

			consumeConn := createConn(uri)
			defer consumeConn.Close()

			publishConn := createConn(uri)
			defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			controlChannel := createChannel(consumeConn)
			defer controlChannel.Close()

			controlStream := declareBindConsumeQueue(controlChannel, "kite-"+name, "join", "private-kite-"+name)
			for {
				select {
				case join, ok := <-controlStream:
					if !ok {
						if !shutdown {
							log.Warn("Connection to AMQP server lost.")
						}
						return
					}
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

						messageChannel := createChannel(consumeConn)
						defer messageChannel.Close()
						messageStream := declareBindConsumeQueue(messageChannel, "", "client-message.*", secretName)

						publishChannel := createChannel(publishConn)
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

				case <-sigtermChannel:
					log.Info("Received TERM signal. Beginning shutdown...")
					beginShutdown()
					controlChannel.Close()
				}
			}
		}()
	}
}
