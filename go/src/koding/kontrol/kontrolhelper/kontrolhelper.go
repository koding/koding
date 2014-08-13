package kontrolhelper

import (
	"encoding/json"
	"io/ioutil"
	"koding/tools/config"
	"koding/tools/slog"
	"os"
	"strconv"
	"strings"

	"github.com/streadway/amqp"
)

type Producer struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
	Name    string
	Done    chan error
}

func NewProducer(name string) *Producer {
	return &Producer{
		Conn:    nil,
		Channel: nil,
		Name:    name,
		Done:    make(chan error),
	}
}

func CreateAmqpConnection(conf *config.Config) *amqp.Connection {
	amqpURI := amqp.URI{
		Scheme:   "amqp",
		Host:     conf.Mq.Host,
		Port:     conf.Mq.Port,
		Username: conf.Mq.ComponentUser,
		Password: conf.Mq.Password,
		Vhost:    conf.Mq.Vhost,
	}

	conn, err := amqp.Dial(amqpURI.String())
	if err != nil {
		slog.Fatalln("AMQP dial: ", err)
	}

	go func() {
		for err := range conn.NotifyClose(make(chan *amqp.Error)) {
			slog.Fatalf("AMQP connection: %s", err.Error())
		}
	}()

	return conn
}

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	go func() {
		for err := range channel.NotifyClose(make(chan *amqp.Error)) {
			slog.Fatalf("AMQP channel: %s", err.Error())
		}
	}()
	return channel
}

func CreateStream(channel *amqp.Channel, kind, exchange, queue, key string, durable, autoDelete bool) <-chan amqp.Delivery {
	if err := channel.ExchangeDeclare(exchange, kind, durable, autoDelete, false, false, nil); err != nil {
		panic(err)
	}

	if _, err := channel.QueueDeclare(queue, true, false, false, false, nil); err != nil {
		panic(err)
	}

	if err := channel.QueueBind(queue, key, exchange, false, nil); err != nil {
		panic(err)
	}

	stream, err := channel.Consume(queue, "", true, true, false, false, nil)
	if err != nil {
		panic(err)
	}

	return stream
}

func CustomHostname(host string) string {
	if host != "" {
		return host
	}

	hostname, err := os.Hostname()
	if err != nil {
		slog.Println(err)
	}

	return hostname
}

func ReadVersion() string {
	file, err := ioutil.ReadFile("VERSION")
	if err != nil {
		slog.Println(err)
	}

	if file == nil {
		slog.Println("Setting default version to 0.0.1")
		return "0.0.1"
	}

	return strings.TrimSpace(string(file))
}

func ReadFile(config string) string {
	file, err := ioutil.ReadFile(config)
	if err != nil {
		slog.Println(err)
	}

	return strings.TrimSpace(string(file))
}

func CreateProducer(conf *config.Config, name string) (*Producer, error) {
	p := NewProducer(name)
	slog.Printf("creating connection for sending %s messages\n", p.Name)
	p.Conn = CreateAmqpConnection(conf)
	p.Channel = CreateChannel(p.Conn)

	return p, nil
}

// TODO: refactor this, it's ugly and I hate functions that take more than tree args.
func RegisterToKontrol(conf *config.Config, name, serviceGenericName, serviceUniqueName, uuid, hostname string, port int) error {

	connection := CreateAmqpConnection(conf)
	channel := CreateChannel(connection)

	type workerMessage struct {
		Command string
		Option  string
	}

	type workerMain struct {
		Name               string
		ServiceGenericName string `json:"serviceGenericName"`
		ServiceUniqueName  string `json:"serviceUniqueName"`
		Uuid               string
		Hostname           string
		Version            int
		Message            workerMessage
		Port               int
	}

	version, err := strconv.Atoi(ReadVersion())
	if err != nil {
		slog.Println(err)
	}

	cmd := workerMain{
		Name:               name,
		ServiceGenericName: serviceGenericName,
		ServiceUniqueName:  serviceUniqueName,
		Uuid:               uuid,
		Hostname:           hostname,
		Message: workerMessage{
			Command: "addWithProxy",
			Option:  "many",
		},
		Port:    port,
		Version: version,
	}

	type Wrap struct{ Worker workerMain }

	data, err := json.Marshal(&Wrap{cmd})
	if err != nil {
		return err
	}

	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		AppId:           uuid,
	}

	if err := channel.ExchangeDeclare("workerExchange", "topic", true, false, false, false, nil); err != nil {
		return err
	}

	err = channel.Publish("workerExchange", "input.worker", false, false, msg)
	if err != nil {
		return err
	}

	err = channel.Close()
	if err != nil {
		slog.Println("could not close kontrold publisher amqp channel", err)
	}

	return nil
}
