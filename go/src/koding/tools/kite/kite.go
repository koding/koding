package kite

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"io"
	"koding/tools/config"
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

type Kite struct {
	Name     string
	Handlers map[string]Handler
}

type Handler struct {
	Concurrent bool
	Callback   func(args *dnode.Partial, session *Session) (interface{}, error)
}

func New(name string) *Kite {
	return &Kite{
		Name:     name,
		Handlers: make(map[string]Handler),
	}
}

func (k *Kite) Handle(method string, concurrent bool, callback func(args *dnode.Partial, session *Session) (interface{}, error)) {
	k.Handlers[method] = Handler{concurrent, callback}
}

func (k *Kite) Run() {
	utils.RunStatusLogger()

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	utils.AmqpAutoReconnect(k.Name+"-kite", func(consumeConn, publishConn *amqp.Connection) {
		routeMap := make(map[string](chan<- []byte))
		defer func() {
			for _, channel := range routeMap {
				close(channel)
			}
		}()

		publishChannel := utils.CreateAmqpChannel(publishConn)
		defer publishChannel.Close()

		consumeChannel := utils.CreateAmqpChannel(consumeConn)
		utils.DeclareAmqpPresenceExchange(consumeChannel, "services-presence", "kite", "kite-"+k.Name, "kite-"+k.Name)
		stream := utils.DeclareBindConsumeAmqpQueue(consumeChannel, "fanout", "kite-"+k.Name, "")

		for {
			select {
			case message, ok := <-stream:
				if !ok {
					return
				}

				switch message.RoutingKey {
				case "auth.join":
					var client struct {
						Username   string
						RoutingKey string
					}
					err := json.Unmarshal(message.Body, &client)
					if err != nil || client.Username == "" || client.RoutingKey == "" {
						log.Err("Invalid auth.join message.", message.Body)
						continue
					}

					if _, found := routeMap[client.RoutingKey]; found {
						continue // duplicate key
					}
					channel := make(chan []byte, 1024)
					routeMap[client.RoutingKey] = channel

					go func() {
						defer log.RecoverAndLog()

						utils.ChangeNumClients <- 1
						log.Debug("Client connected: " + client.Username)
						defer func() {
							utils.ChangeNumClients <- -1
							log.Debug("Client disconnected: " + client.Username)
						}()

						session := NewSession(client.Username)
						defer session.Close()

						d := dnode.New()
						defer d.Close()
						d.OnRootMethod = func(method string, args *dnode.Partial) {
							defer log.RecoverAndLog()

							if method == "ping" {
								d.Send("pong")
								return
							}

							var partials []*dnode.Partial
							err := args.Unmarshal(&partials)
							if err != nil {
								panic(err)
							}

							var options struct {
								WithArgs *dnode.Partial
							}
							err = partials[0].Unmarshal(&options)
							if err != nil {
								panic(err)
							}
							var resultCallback dnode.Callback
							err = partials[1].Unmarshal(&resultCallback)
							if err != nil {
								panic(err)
							}

							handler, found := k.Handlers[method]
							if !found {
								resultCallback(fmt.Sprintf("Method '%v' not known.", method), nil)
								return
							}

							execHandler := func() {
								result, err := handler.Callback(options.WithArgs, session)
								if err != nil {
									resultCallback(err.Error(), result)
								} else if result != nil {
									resultCallback(nil, result)
								}
							}
							if handler.Concurrent {
								go func() {
									defer log.RecoverAndLog()
									execHandler()
								}()
							} else {
								execHandler()
							}
						}

						go func() {
							defer log.RecoverAndLog()
							for data := range d.SendChan {
								log.Debug("Write", client.RoutingKey, data)
								err := publishChannel.Publish("broker", client.RoutingKey, false, false, amqp.Publishing{Body: data})
								if err != nil {
									log.LogError(err, 0)
								}
							}
						}()

						d.Send("ready", "kite-"+k.Name)

						for message := range channel {
							log.Debug("Read", client.RoutingKey, message)
							d.ProcessMessage(message)
						}
					}()

				case "auth.leave":
					var client struct {
						RoutingKey string
					}
					err := json.Unmarshal(message.Body, &client)
					if err != nil || client.RoutingKey == "" {
						log.Err("Invalid auth.leave message.", message.Body)
						continue
					}

					channel, found := routeMap[client.RoutingKey]
					if found {
						close(channel)
						delete(routeMap, client.RoutingKey)
					}

				default:
					channel, found := routeMap[message.RoutingKey]
					if found {
						select {
						case channel <- message.Body:
							// successful
						default:
							close(channel)
							delete(routeMap, message.RoutingKey)
							log.Warn("Dropped client because of message buffer overflow.")
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
		Home: config.Current.GoConfig.HomePrefix + username,
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

func (session *Session) CreateCommand(command ...string) *exec.Cmd {
	var cmd *exec.Cmd
	if config.Current.GoConfig.UseLVE {
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
