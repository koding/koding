package kite

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"io"
	"koding/config"
	"koding/tools/dnode"
	"koding/tools/log"
	"koding/tools/utils"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"strconv"
	"syscall"
	"time"
)

func Run(name string, onRootMethod func(session *Session, method string, args interface{}) (interface{}, error)) {
	runStatusLogger()

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	for !shutdown {
		func() {
			defer time.Sleep(10 * time.Second)
			defer log.RecoverAndLog()

			log.Info("Connecting to AMQP server...")

			notifyCloseChannel := make(chan *amqp.Error)
			consumeConn := utils.CreateAmqpConnection(config.Current.AmqpUri)
			consumeConn.NotifyClose(notifyCloseChannel)
			//defer consumeConn.Close()
			publishConn := utils.CreateAmqpConnection(config.Current.AmqpUri)
			publishConn.NotifyClose(notifyCloseChannel)
			//defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			joinChannel := utils.CreateAmqpChannel(consumeConn)
			joinStream := utils.DeclareBindConsumeAmqpQueue(joinChannel, "kite-"+name, "join", "private-kite-"+name, false)
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
						userName := joinData["user"].(string)
						queue := joinData["queue"].(string)

						changeNumClients <- 1
						log.Debug("Client connected: " + userName)
						defer func() {
							changeNumClients <- -1
							log.Debug("Client disconnected: " + userName)
						}()

						session := newSession(userName)
						defer session.Close()

						d := dnode.New()
						defer d.Close()
						d.OnRootMethod = func(method string, args []interface{}) {
							defer log.RecoverAndLog()
							result, err := onRootMethod(session, method, args[0].(map[string]interface{})["withArgs"])
							if err != nil {
								args[1].(dnode.Callback)(err.Error(), result)
							} else if result != nil {
								args[1].(dnode.Callback)(nil, result)
							}
						}

						go func() {
							publishChannel := utils.CreateAmqpChannel(publishConn)
							defer publishChannel.Close()
							for data := range d.SendChan {
								log.Debug("Write", data)
								err := publishChannel.Publish(queue, "reply-client-message", false, false, amqp.Publishing{Body: data})
								if err != nil {
									panic(err)
								}
							}
						}()

						messageChannel := utils.CreateAmqpChannel(consumeConn)
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

type Session struct {
	User, Home        string
	Uid, Gid          int
	CloseOnDisconnect []io.Closer
}

func newSession(userName string) *Session {
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
	return &Session{
		User: userName,
		Home: config.Current.HomePrefix + userName,
		Uid:  uid,
		Gid:  gid,
	}
}

func (session *Session) Close() {
	for _, closer := range session.CloseOnDisconnect {
		closer.Close()
	}
	session.CloseOnDisconnect = nil
}

func (session *Session) CreateCommand(command []string) *exec.Cmd {
	var cmd *exec.Cmd
	if config.Current.UseLVE {
		cmd = exec.Command("/bin/lve_exec", command...)
	} else {
		cmd = exec.Command(command[0], command[1:]...)
	}
	cmd.Dir = session.Home
	cmd.Env = []string{
		"USER=" + session.User,
		"LOGNAME=" + session.User,
		"HOME=" + session.Home,
		"SHELL=/bin/bash",
		"TERM=xterm",
		"LANG=en_US.UTF-8",
		"PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:" + session.Home + "/bin",
	}
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Credential: &syscall.Credential{
			Uid: uint32(session.Uid),
			Gid: uint32(session.Gid),
		},
	}

	return cmd
}
