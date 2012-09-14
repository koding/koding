package kite

import (
	"github.com/streadway/amqp"
	"io"
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

			notifyCloseChannel := make(chan *amqp.Error)
			consumeConn := createConn(uri)
			consumeConn.NotifyClose(notifyCloseChannel)
			//defer consumeConn.Close()
			publishConn := createConn(uri)
			publishConn.NotifyClose(notifyCloseChannel)
			//defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			joinChannel := createChannel(consumeConn)
			joinStream := declareBindConsumeQueue(joinChannel, "kite-"+name, "join", "private-kite-"+name, false)
			for {
				select {
				case join, ok := <-joinStream:
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

						conn := newConnection(secretName, consumeConn, publishConn)
						defer conn.Close()

						node := dnode.New(conn)
						node.OnRootMethod = func(method string, args []interface{}) {
							result := onRootMethod(user, method, args[0].(map[string]interface{})["withArgs"])
							if result != nil {
								if closer, ok := result.(io.Closer); ok {
									conn.notifyClose(closer)
								}
								args[1].(dnode.Callback)(result)
							}
						}
						node.Run()
					}()

				case err := <-notifyCloseChannel:
					if err != nil {
						panic(err)
					}
					if !shutdown {
						log.Warn("Connection to AMQP server lost.")
					}
					return

				case <-sigtermChannel:
					log.Info("Received TERM signal. Beginning shutdown...")
					beginShutdown()
					joinChannel.Close()
				}
			}
		}()
	}
}
