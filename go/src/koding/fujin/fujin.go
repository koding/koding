package main

import (
	"crypto/tls"
	"encoding/json"
	"koding/fujin/fastproxy"
	"koding/fujin/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/url"
	"sort"
	"strconv"
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

func main() {
	log.Printf("fujin proxy started ")

	// register fujin instance to kontro-daemon
	amqpStream = setupAmqp()
	amqpStream.Publish(buildProxyCmd("addProxy", amqpStream.uuid))

	// get kontrol-daemon database connection
	proxyConfig = proxyconfig.Connect()

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

func targetUrl(numberOfDeaths int, uuid string) *url.URL {
	var target *url.URL
	var err error
	host, key := targetHost(uuid)

	proxy, _ := proxyConfig.GetProxy(uuid)

	// log.Println("Targeting with content:", proxy)

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

	proxy, _ := proxyConfig.GetProxy(uuid)

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

	err := proxyConfig.UpdateProxy(proxy)
	if err != nil {
		log.Println(err)
	}

	return hostname, key
}
