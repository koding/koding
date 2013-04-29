package kite

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"koding/tools/dnode"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type Kite struct {
	Name         string
	Handlers     map[string]Handler
	LoadBalancer func(correlationName string, username string, deadService string) string
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
	changeClientsGauge := lifecycle.CreateClientsGauge()
	log.RunGaugesLoop()

	routeMap := make(map[string](chan<- []byte))
	defer func() {
		for _, channel := range routeMap {
			close(channel)
		}
	}()

	timeoutChannel := make(chan string)

	sigtermChannel := make(chan os.Signal)
	signal.Notify(sigtermChannel, syscall.SIGTERM)

	consumeConn := amqputil.CreateConnection("kite-" + k.Name)
	defer consumeConn.Close()

	publishConn := amqputil.CreateConnection("kite-" + k.Name)
	defer publishConn.Close()

	publishChannel := amqputil.CreateChannel(publishConn)
	defer publishChannel.Close()

	consumeChannel := amqputil.CreateChannel(consumeConn)

	hostname, _ := os.Hostname()
	serviceUniqueName := "kite-" + k.Name + "-" + strconv.Itoa(os.Getpid()) + "|" + strings.Replace(hostname, ".", "_", -1)
	amqputil.JoinPresenceExchange(consumeChannel, "services-presence", "kite", "kite-"+k.Name, serviceUniqueName, k.LoadBalancer != nil)

	stream := amqputil.DeclareBindConsumeQueue(consumeChannel, "fanout", serviceUniqueName, "", true)
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
					log.Warn("Duplicate auth.join for same routing key.")
					continue
				}
				channel := make(chan []byte, 1024)
				routeMap[client.RoutingKey] = channel

				go func() {
					defer log.RecoverAndLog()

					changeClientsGauge(1)
					log.Debug("Client connected: " + client.Username)
					defer func() {
						changeClientsGauge(-1)
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
							resultCallback("Method '"+method+"' not known.", nil)
							return
						}

						execHandler := func() {
							result, err := handler.Callback(options.WithArgs, session)
							if b, ok := result.([]byte); ok {
								result = string(b)
							}

							if err != nil {
								if _, ok := err.(*WrongChannelError); ok {
									if err := publishChannel.Publish("broker", client.RoutingKey+".cycleChannel", false, false, amqp.Publishing{}); err != nil {
										log.LogError(err, 0)
									}
									return
								}

								resultCallback(err.Error(), result)
								return
							}

							resultCallback(nil, result)
						}

						if handler.Concurrent {
							go func() {
								defer log.RecoverAndLog()
								execHandler()
							}()
							return
						}

						execHandler()
					}

					go func() {
						defer log.RecoverAndLog()
						for data := range d.SendChan {
							log.Debug("Write", client.RoutingKey, data)
							if err := publishChannel.Publish("broker", client.RoutingKey, false, false, amqp.Publishing{Body: data}); err != nil {
								log.LogError(err, 0)
							}
						}
					}()

					d.Send("ready", serviceUniqueName)

					for {
						select {
						case message, ok := <-channel:
							if !ok {
								return
							}
							log.Debug("Read", client.RoutingKey, message)
							d.ProcessMessage(message)
						case <-time.After(24 * time.Hour):
							timeoutChannel <- client.RoutingKey
						}
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

			case "auth.who":
				var client struct {
					RoutingKey        string `json:"routingKey"`
					CorrelationName   string `json:"correlationName"`
					Username          string `json:"username"`
					DeadService       string `json:"deadService"`
					ServiceUniqueName string `json:"serviceUniqueName"` // used only for response
				}
				err := json.Unmarshal(message.Body, &client)
				if err != nil || client.Username == "" || client.RoutingKey == "" || client.CorrelationName == "" {
					log.Err("Invalid auth.who message.", message.Body)
					continue
				}
				if k.LoadBalancer == nil {
					log.Err("Got auth.who without having a load balancer.", message.Body)
					continue
				}

				client.ServiceUniqueName = k.LoadBalancer(client.CorrelationName, client.Username, client.DeadService)
				response, err := json.Marshal(client)
				if err != nil {
					log.LogError(err, 0)
					continue
				}
				if err := publishChannel.Publish("auth", "kite.who", false, false, amqp.Publishing{Body: response}); err != nil {
					log.LogError(err, 0)
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

		case routingKey := <-timeoutChannel:
			channel, found := routeMap[routingKey]
			if found {
				close(channel)
				delete(routeMap, routingKey)
				log.Warn("Dropped client because of fallback session timeout.")
			}

		case <-sigtermChannel:
			log.Info("Received TERM signal. Beginning shutdown...")
			lifecycle.BeginShutdown()
			consumeChannel.Close()
		}
	}
}

type Session struct {
	Username     string
	Alive        bool
	onDisconnect []func()
}

func NewSession(username string) *Session {
	return &Session{
		Username: username,
		Alive:    true,
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
