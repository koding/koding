package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/streadway/amqp"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"os/user"
	"strings"
	"syscall"
	"time"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	tag     string
}

type Producer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

type Kdconfig struct {
	Username string `json:"user.name"`
}

type Kdmanifest struct {
	Kitename   string `json:"name"`
	Apiaddress string `json:"apiAddress"`
	Version    string `json:"version"`
	Port       string `json:"port"`
}

type Credentials struct {
	Protocol  string `json:"protocol"`
	Host      string `json:"host"`
	Username  string `json:"username"`
	Password  string `json:"password"`
	Vhost     string `json:"vhost"`
	PublicUrl string `json:"publicUrl"`
}

var producer *Producer
var ticker *time.Ticker
var localPort *string = flag.String("p", "1337", "port to be listened")

func main() {
	ticker = time.NewTicker(time.Millisecond * 500)
	go func() {
		for _ = range ticker.C {
			fmt.Print(". ")
		}
	}()

	cred, err := authUser()
	if err != nil {
		ticker.Stop()
		fmt.Print("could not authorized")
		os.Exit(1)
	}

	producer, err = createProducer(cred)
	if err != nil {
		ticker.Stop()
		fmt.Println(err)
	}

	go signalWatcher(cred.PublicUrl)
	startRouting(cred)

}

func authUser() (Credentials, error) {
	manifest := readManifest()
	query := createApiRequest()
	requestUrl := "http://" + manifest.Apiaddress + "/-/kite/login?" + query

	resp, err := http.DefaultClient.Get(requestUrl)
	if err != nil {
		return Credentials{}, err
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return Credentials{}, err
	}

	if resp.StatusCode == 401 {
		return Credentials{}, fmt.Errorf("Error %s", string(data))
	}

	msg := Credentials{}
	err = json.Unmarshal(data, &msg)
	if err != nil {
		return Credentials{}, err
	}

	return msg, nil
}

func startRouting(cred Credentials) {
	c := &Consumer{
		conn:    nil,
		channel: nil,
		tag:     "",
	}

	var err error

	user := cred.Username
	password := cred.Password
	host := cred.Host
	port := "5672"

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	c.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	c.channel, err = c.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	// err = c.channel.ExchangeDeclare("kontrol-rabbitproxy", "direct", true, false, false, false, nil)
	manifest := readManifest()

	rabbitClient := readUsername() + "-" + manifest.Kitename + "-" + readKey()

	if _, err := c.channel.QueueDeclare("", false, true, true, false, nil); err != nil {
		log.Fatalf("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", rabbitClient, "kontrol-rabbitproxy", false, nil); err != nil {
		log.Fatalf("queue.bind: %s", err)
	}

	httpStream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("basic.consume: %s", err)
	}

	ticker.Stop()
	fmt.Printf("\nyour public url: %s\n", cred.PublicUrl)
	for msg := range httpStream {
		// log.Printf("got %dB message data: [%v]-[%s] %s",
		// 	len(msg.Body),
		// 	msg.DeliveryTag,
		// 	msg.RoutingKey,
		// 	msg.Body)

		body, err := doRequest(msg.Body)
		if err != nil {
			fmt.Println(err)
			go publishToRemote(nil, msg.CorrelationId, msg.ReplyTo)
		} else {
			go publishToRemote(body, msg.CorrelationId, msg.ReplyTo)
		}

	}
}

func doRequest(msg []byte) ([]byte, error) {
	buf := bytes.NewBuffer(msg)
	reader := bufio.NewReader(buf)
	req, err := http.ReadRequest(reader)
	if err != nil {
		fmt.Println(err)
	}

	// Request.RequestURI can't be set in client requests.
	// http://golang.org/src/pkg/net/http/client.go
	req.RequestURI = ""

	ok := hasPort(req.URL.Host)
	if !ok {
		manifest := readManifest()
		req.URL.Host = addPort(req.URL.Host, manifest.Port)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	output := new(bytes.Buffer)
	resp.Write(output)

	return output.Bytes(), nil
}

func publishToRemote(data []byte, id, routingKey string) {
	msg := amqp.Publishing{
		ContentType:   "text/plain",
		Body:          data,
		CorrelationId: id,
	}

	err := producer.channel.Publish("kontrol-rabbitproxy", routingKey, false, false, msg)
	if err != nil {
		fmt.Printf("error while publishing proxy message: %s", err)
	}

}

func createProducer(cred Credentials) (*Producer, error) {
	p := &Producer{
		conn:    nil,
		channel: nil,
	}

	var err error

	user := cred.Username
	password := cred.Password
	host := cred.Host
	port := "5672"

	url := "amqp://" + user + ":" + password + "@" + host + ":" + port
	p.conn, err = amqp.Dial(url)
	if err != nil {
		log.Fatal(err)
	}

	p.channel, err = p.conn.Channel()
	if err != nil {
		log.Fatal(err)
	}

	return p, nil
}

func createApiRequest() string {
	kiteKey := readKey()
	manifest := readManifest()
	userName := readUsername()

	v := url.Values{}
	v.Set("type", "webserver")
	v.Set("key", kiteKey)
	v.Set("name", manifest.Kitename)
	v.Set("version", manifest.Version)
	v.Set("username", userName)

	return v.Encode()
}

func readKey() string {
	usr, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}

	keyfile := usr.HomeDir + "/.kd/koding.key.pub"

	file, err := ioutil.ReadFile(keyfile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	return strings.TrimSpace(string(file))
}

func readUsername() string {
	usr, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}

	configfile := usr.HomeDir + "/.kdconfig"

	file, err := ioutil.ReadFile(configfile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	kdconfig := Kdconfig{}
	err = json.Unmarshal(file, &kdconfig)
	if err != nil {
		fmt.Println(err)
	}

	return kdconfig.Username
}

func readManifest() Kdmanifest {
	usr, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}

	configfile := usr.HomeDir + "/.kd/server.json"

	file, err := ioutil.ReadFile(configfile)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	kdmanifest := Kdmanifest{}
	err = json.Unmarshal(file, &kdmanifest)
	if err != nil {
		fmt.Println(err)
		return Kdmanifest{}
	}

	return kdmanifest
}

func checkServer(host string) error {
	c, err := net.Dial("tcp", host)
	if err != nil {
		return err
	}
	c.Close()
	return nil
}

// Given a string of the form "host", "host:port", or "[ipv6::address]:port",
// return true if the string includes a port.
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// Given a string of the form "host", "port", returns "host:port"
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}

func signalWatcher(url string) {
	// For future reference, if we can do stuff for ctrl+c
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM:
			fmt.Printf(" disconnected from: %s\n", url)
			os.Exit(1)
		}
	}
}
