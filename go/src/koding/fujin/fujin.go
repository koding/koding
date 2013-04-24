package main

import (
	"crypto/tls"
	"encoding/json"
	"github.com/gorilla/mux"
	"github.com/streadway/amqp"
	"koding/fujin/fastproxy"
	"koding/fujin/proxyconfig"
	"koding/tools/config"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"time"
)

func init() {
	log.SetPrefix("fujin ")
}

type IncomingMessage struct {
	ProxyResponse *proxyconfig.ProxyResponse
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
	log.Printf("register fujin to kontrold with uuid '%s'", amqpStream.uuid)
	amqpStream.Publish(buildProxyCmd("addProxy", amqpStream.uuid))
	log.Println("register command is send. waiting for response from kontrold...")
	go handleInput(amqpStream.input, amqpStream.uuid)

	select {
	case <-time.After(time.Second * 15):
		log.Fatalf("ERROR: no repsonse received from kontrold, aborting process.")
		os.Exit(1)
	case <-start: // wait until we got message from kontrold or exit via above chan
	}

	// addHTTP, err := net.ResolveTCPAddr("tcp", ":"+config.HttpPort)
	// if err != nil {
	// 	log.Println(err)
	// 	return
	// }

	// addHTTPS, err := net.ResolveTCPAddr("tcp", ":"+config.HttpsPort)
	// if err != nil {
	// 	log.Println(err)
	// 	return
	// }

	// cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
	// if err != nil {
	// 	log.Println("https mode is disabled. please add cert.pem and key.pem files.")
	// } else {
	// 	log.Printf("https mode is enabled. serving at :%s ...", config.HttpsPort)
	// 	go listenProxy(addHTTPS, &cert, amqpStream.uuid)
	// }

	// log.Printf("normal mode is enabled. serving at :%s ...", config.HttpPort)
	// listenProxy(addHTTP, nil, amqpStream.uuid)

	// start one with go in order not to block the other one

	r := mux.NewRouter()
	r.Handle("/", newReverseProxy())
	http.Handle("/", r)

	go func() {
		err = http.ListenAndServeTLS(":"+config.HttpsPort, "cert.pem", "key.pem", nil)
		if err != nil {
			log.Println("https mode is disabled. please add cert.pem and key.pem files.")
		} else {
			log.Printf("https mode is enabled. serving at :%s ...", config.HttpsPort)
		}
	}()

	log.Printf("normal mode is enabled. serving at :%s ...", config.HttpPort)
	http.ListenAndServe(":"+config.HttpPort, nil)
}

func newReverseProxy() *httputil.ReverseProxy {
	director := func(req *http.Request) {
		log.Println("HOST:", req.RequestURI, req.Host)
		var deaths int
		name, key := parseKey(req.Host)
		if name == "homepage" {
			log.Println("Hello world!")
			return
		}

		target := targetUrl(deaths, name, key)

		targetQuery := target.RawQuery

		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.URL.Path = singleJoiningSlash(target.Path, req.URL.Path)
		if targetQuery == "" || req.URL.RawQuery == "" {
			req.URL.RawQuery = targetQuery + req.URL.RawQuery
		} else {
			req.URL.RawQuery = targetQuery + "&" + req.URL.RawQuery
		}
	}

	return &httputil.ReverseProxy{Director: director}
}

func listenProxy(localAddr *net.TCPAddr, cert *tls.Certificate, uuid string) {
	err := fastproxy.Listen(localAddr, cert, func(req fastproxy.Request) {
		var deaths int
		name, key := parseKey(req.Host)
		if name == "homepage" {
			req.Write("Hello fujin proxy!")
			return
		}

		target := targetUrl(deaths, name, key)
		remoteAddr, err := net.ResolveTCPAddr("tcp", target.Host)
		if err != nil {
			log.Println(err)
			return
		}

		if err := req.Relay(remoteAddr); err != nil {
			log.Println(err)
			req.Redirect("http://example.com")
		}
	})

	if err != nil {
		log.Fatalf("FATAL ERROR: %s", err)
	}
}

func parseKey(host string) (string, string) {
	log.Println("HOST string", host)
	counts := strings.Count(host, "-")
	log.Println("count string", counts)
	if counts == 0 {
		return "homepage", ""
	}

	partsFirst := strings.Split(host, ".")
	firstSub := partsFirst[0]

	partsSecond := strings.Split(firstSub, "-")
	name := partsSecond[0]
	key := partsSecond[1]

	return name, key
}

func handleInput(input <-chan amqp.Delivery, uuid string) {
	for {
		select {
		case d := <-input:
			// log.Printf("got %dB message data: [%v] %s",
			// 	len(d.Body),
			// 	d.DeliveryTag,
			// 	d.Body)

			var msg IncomingMessage

			err := json.Unmarshal(d.Body, &msg)
			if err != nil {
				log.Print("bad json incoming msg: ", err)
			}

			if msg.ProxyResponse != nil {
				if msg.ProxyResponse.Action == "updateProxy" {
					log.Println("update action received from kontrold. updating proxy route table")
					var err error
					proxy, err = proxyDB.GetProxy(uuid)
					if err != nil {
						log.Println(err)
					}

					if first {
						start <- true
						first = false
						log.Println("routing tables updated. ready to start servers.")
					}

				}

			} else {
				log.Println("incoming message is in wrong format")
			}
		}
	}
}

func targetUrl(numberOfDeaths int, name, key string) *url.URL {
	var target *url.URL
	var err error
	host := targetHost(name, key)

	keyRoutingTable := proxy.Services[name]
	v := len(keyRoutingTable.Keys[key])
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

		target = targetUrl(numberOfDeaths, name, key)
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

func targetHost(name, key string) string {
	var hostname string

	keyRoutingTable := proxy.Services[name]

	v := len(keyRoutingTable.Keys)
	if v == 0 {
		hostname = "localhost:8000"
		log.Println("no keys are added, using default url ", hostname)
	} else {
		// use round-robin algorithm for each hostname
		for i, value := range keyRoutingTable.Keys[key] {
			currentIndex := value.CurrentIndex
			if currentIndex == i {
				hostname = value.Host
				for k, _ := range keyRoutingTable.Keys[key] {
					if len(keyRoutingTable.Keys[key])-1 == currentIndex {
						keyRoutingTable.Keys[key][k].CurrentIndex = 0 // reached end
					} else {
						keyRoutingTable.Keys[key][k].CurrentIndex = currentIndex + 1
					}
				}
				break
			}
		}
	}

	return hostname
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

// this is from ReverseProxy.go, can change..
func singleJoiningSlash(a, b string) string {
	aslash := strings.HasSuffix(a, "/")
	bslash := strings.HasPrefix(b, "/")
	switch {
	case aslash && bslash:
		return a + b[1:]
	case !aslash && !bslash:
		return a + "/" + b
	}
	return a + b
}
