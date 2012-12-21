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
)

func Run(name string, onRootMethod func(session *Session, method string, args *dnode.Partial) (interface{}, error)) {
	utils.RunStatusLogger()

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	utils.AmqpAutoReconnect(name+"-kite", func(consumeConn, publishConn *amqp.Connection) {
		joinChannel := utils.CreateAmqpChannel(consumeConn)
		joinStream := utils.DeclareBindConsumeAmqpQueue(joinChannel, "kite-"+name, "join", "private-kite-"+name, false)

		presenceChannel := utils.CreateAmqpChannel(consumeConn)
		utils.XDeclareAmqpPresenceExchange(presenceChannel, "services-presence", "kite", "kite-"+name, "private-kite-"+name)

		for {
			select {
			case join, ok := <-joinStream:
				if !ok {
					return
				}
				go func() {
					defer log.RecoverAndLog()

					joinData := make(map[string]interface{})
					json.Unmarshal(join.Body, &joinData)
					userName := joinData["user"].(string)
					queue := joinData["queue"].(string)

					utils.ChangeNumClients <- 1
					log.Debug("Client connected: " + userName)
					defer func() {
						utils.ChangeNumClients <- -1
						log.Debug("Client disconnected: " + userName)
					}()

					session := NewSession(userName)
					defer session.Close()

					d := dnode.New()
					defer d.Close()
					d.OnRootMethod = func(method string, args *dnode.Partial) {
						go func() {
							defer log.RecoverAndLog()

							var partials []*dnode.Partial
							err := args.Unmarshal(&partials)
							if err != nil {
								panic(err)
							}

							var options map[string]*dnode.Partial
							err = partials[0].Unmarshal(&options)
							if err != nil {
								panic(err)
							}
							var callback dnode.Callback
							err = partials[1].Unmarshal(&callback)
							if err != nil {
								panic(err)
							}

							result, err := onRootMethod(session, method, options["withArgs"])
							if err != nil {
								callback(err.Error(), result)
							} else if result != nil {
								callback(nil, result)
							}
						}()
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

			case <-sigtermChannel:
				log.Info("Received TERM signal. Beginning shutdown...")
				utils.BeginShutdown()
				joinChannel.Close()
			}
		}
	})
}

type Session struct {
	User, Home string
	Uid, Gid   int
	closers    []io.Closer
}

func NewSession(userName string) *Session {
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

func (session *Session) CloseOnDisconnect(closer io.Closer) {
	session.closers = append(session.closers, closer)
}

func (session *Session) Close() {
	for _, closer := range session.closers {
		closer.Close()
	}
	session.closers = nil
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
