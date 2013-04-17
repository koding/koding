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
	// "sort"
	// "strconv"
	"strings"
	"time"
)

func init() {
	log.SetPrefix("fujin ")
}

type IncomingMessage struct {
	ProxyConfiguration *proxyconfig.ProxyConfiguration
	ProxyMessage       *proxyconfig.ProxyMessage
}

var proxy proxyconfig.Proxy // this will be only updated whenever we receive a msg from kontrold
var proxyDB *proxyconfig.ProxyConfiguration
var amqpStream *AmqpStream
var start chan bool
var first bool = true

func main() {
	log.Printf("fujin proxy started ")
	start = make(chan bool)

	// open kontrol-daemon database connection
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	// register fujin instance to kontrol-daemon
	amqpStream = setupAmqp()
	amqpStream.Publish(buildProxyCmd("addProxy", amqpStream.uuid))
	go handleInput(amqpStream.input, amqpStream.uuid)

	log.Printf("registering with uuid '%s'", amqpStream.uuid)
	log.Println("send request to get config file from kontrold. waiting...")
	select {
	case <-time.After(time.Second * 15):
		log.Fatalf("ERROR: no config received from kontrold, aborting process.")
		os.Exit(1)
	case <-start: // wait until we got message from kontrold or exit via above chan
	}

	addHTTP, err := net.ResolveTCPAddr("tcp", ":"+config.HttpPort)
	if err != nil {
		log.Println(err)
		return
	}

	addHTTPS, err := net.ResolveTCPAddr("tcp", ":"+config.HttpsPort)
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

		args := strings.Split(req.Host, ".")
		key := args[0]
		log.Println("key is:", key)

		target := targetUrl(deaths, key)

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

func handleInput(input <-chan amqp.Delivery, uuid string) {
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
				// TODO: should receive simple json, something like updateProxy...
				log.Println("received config from kontrold, starting servers...")

				var err error
				proxy, err = proxyDB.GetProxy(uuid)
				if err != nil {
					log.Println(err)
				}

				log.Println("debug", proxy)

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

func targetUrl(numberOfDeaths int, key string) *url.URL {
	var target *url.URL
	var err error
	host := targetHost(key)

	v := len(proxy.KeyRoutingTable.Keys[key])
	if v == numberOfDeaths {
		log.Println("All given servers are death. Fallback to localhost:8000")
		target, err = url.Parse("http://localhost:8000")
		if err != nil {
			log.Fatal(err)
		}
		return target
	}

	err = checkServer(host)
	if err != nil {
		log.Println(err)
		log.Printf("Server is death: %s. Trying to get another one", host)
		numberOfDeaths++

		target = targetUrl(numberOfDeaths, key)
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
func checkServer(host string) error {
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

func targetHost(key string) string {
	var hostname string

	v := len(proxy.KeyRoutingTable.Keys)
	if v == 0 {
		hostname = "localhost:8000"
		log.Println("no keys are added, using default url ", hostname)
	} else {
		// // get all keys and sort them
		// listOfKeys := make([]int, len(proxy.KeyRoutingTable.Keys))
		// i := 0
		// for k, _ := range proxy.KeyRoutingTable.Keys {
		// 	listOfKeys[i], _ = strconv.Atoi(k)
		// 	i++
		// }
		// sort.Ints(listOfKeys)

		// // give precedence to the largest key number
		// key = strconv.Itoa(listOfKeys[len(listOfKeys)-1])

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

	return hostname
}
