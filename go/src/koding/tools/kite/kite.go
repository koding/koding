package kite

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"io"
	"koding/tools/dnode"
	"koding/tools/log"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"strconv"
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

						joinData := make(map[string]interface{})
						json.Unmarshal(join.Body, &joinData)
						user := joinData["user"].(string)
						queue := joinData["queue"].(string)

						changeNumClients <- 1
						log.Debug("Client connected: " + user)
						defer func() {
							changeNumClients <- -1
							log.Debug("Client disconnected: " + user)
						}()

						closers := make([]io.Closer, 0)
						defer func() {
							for _, closer := range closers {
								closer.Close()
							}
						}()

						d := dnode.New()
						defer d.Close()
						d.OnRootMethod = func(method string, args []interface{}) {
							defer log.RecoverAndLog()
							result := onRootMethod(user, method, args[0].(map[string]interface{})["withArgs"])
							if result != nil {
								if closer, ok := result.(io.Closer); ok {
									closers = append(closers, closer)
								}
								args[1].(dnode.Callback)(result)
							}
						}

						go func() {
							publishChannel := createChannel(publishConn)
							defer publishChannel.Close()
							for data := range d.SendChan {
								log.Debug("Write", data)
								err := publishChannel.Publish(queue, "reply-client-message", false, false, amqp.Publishing{Body: data})
								if err != nil {
									panic(err)
								}
							}
						}()

						messageChannel := createChannel(consumeConn)
						defer messageChannel.Close()
						messageStream, err := messageChannel.Consume(queue, "", true, false, false, false, nil)
						if err != nil {
							panic(err)
						}

						for message := range messageStream {
							if message.RoutingKey == "disconnected" {
								message.Cancel(true) // stop consuming
							} else {
								log.Debug("Read", message.Body)
								d.ProcessMessage(message.Body)
							}
						}
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

func CreateCommand(command []string, userName, homePrefix string) *exec.Cmd {
	userData, err := user.Lookup(userName)
	if err != nil {
		panic(err)
	}
	uid, err := strconv.Atoi(userData.Uid)
	if err != nil {
		panic(err)
	}
	gid, err := strconv.Atoi(userData.Gid)
	if err != nil {
		panic(err)
	}
	if uid == 0 || gid == 0 {
		panic("SECURITY BREACH: User lookup returned root.")
	}

	cmd := exec.Command(command[0], command[1:]...)
	cmd.Dir = homePrefix + userName
	cmd.Env = []string{
		"USER=" + userName,
		"LOGNAME=" + userName,
		"HOME=" + homePrefix + userName,
		"SHELL=/bin/bash",
		"TERM=xterm",
		"LANG=en_US.UTF-8",
		"PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:" + homePrefix + userName + "/bin",
	}
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Credential: &syscall.Credential{
			Uid: uint32(uid),
			Gid: uint32(gid),
		},
	}

	return cmd
}
