package kite

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/config"
	"koding/tools/db"
	"koding/tools/dnode"
	"koding/tools/log"
	"koding/tools/utils"
	"os"
	"os/signal"
	"sync"
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
		var routeMapMutex sync.RWMutex
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
						d.OnRootMethod = func(method string, args *dnode.Partial) {
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
								result, err := handler.Callback(options["withArgs"], session)
								if b, ok := result.([]byte); ok {
									result = string(b)
								}
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
								log.Debug("Write", routingKey, data)
								err := publishChannel.Publish("broker", routingKey, false, false, amqp.Publishing{Body: data})
								if err != nil {
									panic(err)
								}
							}
						}()

						d.Send("ready", "kite-"+k.Name)

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
	User         *db.User
	Home         string
	Alive        bool
	onDisconnect []func()
}

func NewSession(username string) *Session {
	user, err := db.FindUserByName(username)
	if err != nil {
		panic(err)
	}
	if user.Id == 0 {
		panic("SECURITY BREACH: User lookup returned root.")
	}

	return &Session{
		User:  user,
		Home:  config.Current.HomePrefix + username,
		Alive: true,
	}
}

func (session *Session) OnDisconnect(f func()) {
	session.onDisconnect = append(session.onDisconnect, f)
}

func (session *Session) Close() {
	session.Alive = false
	for _, f := range session.onDisconnect {
		f()
	}
	session.onDisconnect = nil
}
