package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	// "github.com/koding/rabbitapi"
	"github.com/streadway/amqp"
	"io/ioutil"
	"log"
	"net/http"
	"os/user"
	"strings"
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

type Credentials struct {
	Protocol  string `json:"protocol"`
	Host      string `json:"host"`
	Username  string `json:"username"`
	Password  string `json:"password"`
	Vhost     string `json:"vhost"`
	PublicUrl string `json:"publicUrl"`
}

var producer *Producer

func main() {
	fmt.Println("koding local proxy is starting...")

	clientKey := readKey()
	fmt.Printf("auth for key: %s and kite-name: proxy\n", clientKey)
	cred, err := authUser(clientKey)
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println("auth is successfull")

	producer, err = createProducer(cred)
	if err != nil {
		log.Println(err)
	}
	startRouting(cred)
}

func authUser(key string) (Credentials, error) {
	registerApi := fmt.Sprintf("http://localhost:3020/-/proxy/login?rabbitkey=%s&name=proxy&key=1&host=localhost:8004", key)
	resp, err := http.DefaultClient.Get(registerApi)
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

	// log.Println(string(data)) // debug

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

	// err = c.channel.ExchangeDeclare("kontrol-rabbitproxy", "direct", false, true, false, false, nil)
	// if err != nil {
	// 	log.Fatal("exchange.declare: %s", err)
	// }
	clientKey := readKey()
	if _, err := c.channel.QueueDeclare("", false, true, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind("", clientKey, "kontrol-rabbitproxy", false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	httpStream, err := c.channel.Consume("", "", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	fmt.Printf("your public url: %s\nyour local port: 4000\n", cred.PublicUrl)
	fmt.Print("proxy is ready and working...")
	for msg := range httpStream {
		// log.Printf("got %dB message data: [%v]-[%s] %s",
		// 	len(msg.Body),
		// 	msg.DeliveryTag,
		// 	msg.RoutingKey,
		// 	msg.Body)

		body, err := doRequest(msg.Body)
		if err != nil {
			log.Println(err)
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
		log.Println(err)
	}

	// Request.RequestURI can't be set in client requests.
	// http://golang.org/src/pkg/net/http/client.go
	req.RequestURI = ""
	log.Println("Doing a http request to", req.URL.Host)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	output := new(bytes.Buffer)
	resp.Write(output)

	// log.Println("Response is", string(data))

	return output.Bytes(), nil
}

func publishToRemote(data []byte, id, routingKey string) {
	msg := amqp.Publishing{
		ContentType:   "text/plain",
		Body:          data,
		CorrelationId: id,
	}

	fmt.Println("publishing repsonse to", routingKey)
	err := producer.channel.Publish("kontrol-rabbitproxy", routingKey, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
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

func readKey() string {
	usr, err := user.Current()
	if err != nil {
		log.Fatal(err)
	}

	keyfile := usr.HomeDir + "/.kd/koding.key"

	file, err := ioutil.ReadFile(keyfile)
	if err != nil {
		log.Println(err)
	}

	return strings.TrimSpace(string(file))
}
