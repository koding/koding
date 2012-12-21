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
	"sync"
	"syscall"
)

func Run(name string, onRootMethod func(session *Session, method string, args *dnode.Partial) (interface{}, error)) {
	utils.RunStatusLogger()

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	utils.AmqpAutoReconnect(name+"-kite", func(consumeConn, publishConn *amqp.Connection) {
		routeMap := make(map[string](chan<- []byte))
		var routeMapMutex sync.RWMutex

		publishChannel := utils.CreateAmqpChannel(publishConn)
		defer publishChannel.Close()

		consumeChannel := utils.CreateAmqpChannel(consumeConn)
		utils.DeclareAmqpPresenceExchange(consumeChannel, "services-presence", "kite", "kite-"+name, "kite-"+name)
		stream := utils.DeclareBindConsumeAmqpQueue(consumeChannel, "fanout", "kite-"+name, "")

		for {
			select {
			case message, ok := <-stream:
				if !ok {
					return
				}

				switch message.RoutingKey {
				case "auth.join":
					arguments := make(map[string]interface{})
					json.Unmarshal(message.Body, &arguments)
					username := arguments["username"].(string)
					routingKey := arguments["routingKey"].(string)

					channel := make(chan []byte, 1024)
					routeMapMutex.Lock()
					if _, found := routeMap[routingKey]; found {
						routeMapMutex.Unlock()
						continue // duplicate key
					}
					routeMap[routingKey] = channel
					routeMapMutex.Unlock()

					go func() {
						defer log.RecoverAndLog()

						utils.ChangeNumClients <- 1
						log.Debug("Client connected: " + username)
						defer func() {
							utils.ChangeNumClients <- -1
							log.Debug("Client disconnected: " + username)
						}()

						session := NewSession(username)
						defer session.Close()

						d := dnode.New()
						defer d.Close()
						log.Debug("Trying to send")
						d.Send("ready", nil)
						log.Debug("After send")
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
							defer log.RecoverAndLog()
							for data := range d.SendChan {
								log.Debug("Write", routingKey, data)
								err := publishChannel.Publish("broker", routingKey, false, false, amqp.Publishing{Body: data})
								if err != nil {
									panic(err)
								}
							}
						}()

						for message := range channel {
							log.Debug("Read", routingKey, message)
							d.ProcessMessage(message)
						}
					}()

				case "auth.leave":
					arguments := make(map[string]interface{})
					json.Unmarshal(message.Body, &arguments)
					routingKey := arguments["routingKey"].(string)
					routeMapMutex.Lock()
					channel, found := routeMap[routingKey]
					if found {
						close(channel)
						delete(routeMap, routingKey)
					}
					routeMapMutex.Unlock()

				default:
					routeMapMutex.RLock()
					channel, found := routeMap[message.RoutingKey]
					routeMapMutex.RUnlock()
					if found {
						select {
						case channel <- message.Body:
							// successful
						default:
							log.Warn("Dropped message")
						}
					}
				}

			case <-sigtermChannel:
				log.Info("Received TERM signal. Beginning shutdown...")
				utils.BeginShutdown()
				consumeChannel.Close()
			}
		}
	})
}

type Session struct {
	User, Home string
	Uid, Gid   int
	closers    []io.Closer
}

func NewSession(username string) *Session {
	userData, err := user.Lookup(username)
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
		User: username,
		Home: config.Current.HomePrefix + username,
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
