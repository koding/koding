package main

import (
	"crypto/tls"
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/fujin/fastproxy"
	"koding/fujin/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/url"
	"os"
	"os/signal"
	"sort"
	"strconv"
	"syscall"
)

func init() {
	log.SetPrefix("fujin ")
}

type IncomingMessage struct {
	ProxyConfiguration *proxyconfig.ProxyConfiguration
	ProxyMessage       *proxyconfig.ProxyMessage
}

var proxyConfig *proxyconfig.ProxyConfiguration
var amqpStream *AmqpStream
var start chan bool
var first bool = true

func main() {
	log.Printf("proxy started ")
	start = make(chan bool)

	if config.EnableAmqp {
		amqpStream = setupAmqp()
		go handleInput(amqpStream.input)
		go signalWatcher() // used for deleting proxy in kontrold after quitting
	}

	proxyConfig = proxyconfig.NewProxyConfiguration()
	err := proxyConfig.ReadConfig()
	if err != nil {
		if config.EnableAmqp {
			log.Printf("registering with uuid '%s'", amqpStream.uuid)
			data := buildProxyCmd("addProxy", amqpStream.uuid)
			amqpStream.Publish(data)
			log.Println("send request to get config file from kontrold")
			<-start
			log.Println("got configuration message")
		} else {
			log.Println(err)
			log.Printf("please create or enable amqp messaging")
			return
		}

	}

	addHTTP, err := net.ResolveTCPAddr("tcp", "localhost:"+config.HttpPort)
	if err != nil {
		log.Println(err)
		return
	}

	addHTTPS, err := net.ResolveTCPAddr("tcp", "localhost:"+config.HttpsPort)
	if err != nil {
		log.Println(err)
		return
	}

	cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
	if err != nil {
		log.Println(err)
		log.Println("https mode is disabled... please add cert.pem and key.pem files.")
	} else {
		log.Printf("serving at https://localhost:%s...", config.HttpsPort)
		go listenProxy(addHTTPS, &cert, amqpStream.uuid)
	}

	log.Printf("serving at http://localhost:%s...", config.HttpPort)
	listenProxy(addHTTP, nil, amqpStream.uuid)
}

func listenProxy(localAddr *net.TCPAddr, cert *tls.Certificate, uuid string) {
	err := fastproxy.Listen(localAddr, cert, func(req fastproxy.Request) {
		var deaths int
		target := targetUrl(deaths, uuid)

		remoteAddr, err := net.ResolveTCPAddr("tcp", target.Host)
		if err != nil {
			log.Println(err)
			return
		}

		if err := req.Relay(remoteAddr); err != nil {
			log.Println(err)
			// req.Redirect("http://www.koding.com/notactive.html")
		}
	})

	if err != nil {
		log.Fatalf("FATAL ERROR: %s", err)
	}
}

func buildProxyCmd(action, uuid string) []byte {
	var req proxyconfig.ProxyMessage
	req.Action = action
	req.Uuid = uuid

	data, err := json.Marshal(req)
	if err != nil {
		log.Println("json marshall error", err)
	}

	return data
}

func handleInput(input <-chan amqp.Delivery) {
	log.Println("amqp mode is enabled. start listen to amqp messages...")
	for {
		select {
		case d := <-input:
			// log.Printf("got %dB message data: [%v] %s", len(d.Body), d.DeliveryTag, d.Body)
			var msg IncomingMessage

			err := json.Unmarshal(d.Body, &msg)
			if err != nil {
				log.Print("bad json incoming msg: ", err)
			}

			if msg.ProxyConfiguration != nil {
				log.Println("received config from kontrold, starting servers...")
				proxyConfig = msg.ProxyConfiguration

				if err := proxyConfig.SaveConfig(); err != nil {
					log.Printf(" %s", err)
					return
				}

				if first {
					start <- true
					first = false
				}
			} else if msg.ProxyMessage != nil {
				log.Println("Got ProxyMessage", msg.ProxyMessage)
			} else {
				log.Println("incoming message is in wrong format")
			}
		}
	}
}

func targetUrl(numberOfDeaths int, uuid string) *url.URL {
	var target *url.URL
	var err error
	host, key := targetHost(uuid)

	proxy := proxyConfig.RegisteredProxies[uuid]

	v := len(proxy.KeyRoutingTable.Keys[key])
	if v == numberOfDeaths {
		log.Println("All given servers are death. Fallback to localhost:8000")
		target, err = url.Parse("http://localhost:8000")
		if err != nil {
			log.Fatal(err)
		}
		return target
	}

	err = checkServer(host, key)
	if err != nil {
		log.Println(err)
		log.Printf("Server is death: %s. Trying to get another one", host)
		numberOfDeaths++

		target = targetUrl(numberOfDeaths, uuid)
	} else {
		target, err = url.Parse("http://" + host)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("got / request. using proxy to %s (key: %s)", target.Host, key)
	}
	return target
}

// Implement with fastProxy ...
func checkServer(host, key string) error {
	remoteAddr, err := net.ResolveTCPAddr("tcp", host)
	if err != nil {
		return err
	}

	remoteConn, err := net.DialTCP("tcp", nil, remoteAddr)
	if err != nil {
		return err
	}

	remoteConn.Close()
	return nil
}

func targetHost(uuid string) (string, string) {
	var hostname string
	key := ""

	proxy := proxyConfig.RegisteredProxies[uuid]

	v := len(proxy.KeyRoutingTable.Keys)
	if v == 0 {
		hostname = "localhost:8000"
		log.Println("no keys are added, using default url ", hostname)
	} else {
		// get all keys and sort them
		listOfKeys := make([]int, len(proxy.KeyRoutingTable.Keys))
		i := 0
		for k, _ := range proxy.KeyRoutingTable.Keys {
			listOfKeys[i], _ = strconv.Atoi(k)
			i++
		}
		sort.Ints(listOfKeys)

		// give precedence to the largest key number
		key = strconv.Itoa(listOfKeys[len(listOfKeys)-1])

		// then use round-robin algorithm for each hostname
		for i, value := range proxy.KeyRoutingTable.Keys[key] {
			currentIndex := value.CurrentIndex
			if currentIndex == i {
				hostname = value.Host
				for k, _ := range proxy.KeyRoutingTable.Keys[key] {
					if len(proxy.KeyRoutingTable.Keys[key])-1 == currentIndex {
						proxy.KeyRoutingTable.Keys[key][k].CurrentIndex = 0 // reached end
					} else {
						proxy.KeyRoutingTable.Keys[key][k].CurrentIndex = currentIndex + 1
					}
				}
				break
			}
		}
	}

	return hostname, key
}

func signalWatcher() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM:
			data := buildProxyCmd("deleteProxy", amqpStream.uuid)
			amqpStream.Publish(data)
			log.Println("deleteProxy data sended")
			log.Fatalf("received '%s' signal; exiting", signal)
			os.Exit(1)
		default:
			log.Printf("received '%s' signal; unhandled", signal)
		}
	}
}
