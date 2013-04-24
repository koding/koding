package proxy

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/fujin/proxyconfig"
	"koding/tools/amqputil"
	"koding/tools/config"
	"log"
)

type Producer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	name    string
	done    chan error
}

func NewProducer(name string) *Producer {
	return &Producer{
		conn:    nil,
		channel: nil,
		name:    name,
		done:    make(chan error),
	}
}

var proxyProducer *Producer
var proxyConfig *proxyconfig.ProxyConfiguration

func Startup() {
	var err error
	proxyProducer, err = createProducer("proxy")
	if err != nil {
		log.Println(err)
	}

	err = proxyProducer.channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	proxyConfig, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	log.Println("kontrold proxy plugin has started")
}

func HandleMessage(data []byte) {
	var msg proxyconfig.ProxyMessage

	err := json.Unmarshal(data, &msg)
	if err != nil {
		log.Print("bad json incoming msg: ", err)
	}

	DoProxy(msg)
}

func DoProxy(msg proxyconfig.ProxyMessage) {
	switch msg.Action {
	case "addProxy":
		log.Println("got 'addProxy' json request")
		err := proxyConfig.AddProxy(msg.Uuid)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addKey":
		log.Println("got 'addKey' json request")
		err := proxyConfig.AddKey(msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addDomain":
		log.Println("got 'addDomain' json request")
		err := proxyConfig.AddDomain(msg.DomainName, msg.ServiceName, msg.Key, msg.Host, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "deleteProxy":
		log.Println("got 'deleteProxy' json request")
		err := proxyConfig.DeleteProxy(msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteKey":
		log.Println("got 'deleteKey' json request")
		err := proxyConfig.DeleteKey(msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	default:
		log.Println("invalid action", msg.Action)
	}
}

func sendResponse(action, appId string) {
	log.Printf("sending '%s' response to proxy", action)
	type Wrap struct {
		ProxyResponse *proxyconfig.ProxyResponse
	}

	response := &proxyconfig.ProxyResponse{
		Action: action,
		Uuid:   appId,
	}

	data, err := json.Marshal(&Wrap{response})
	if err != nil {
		log.Println("Json marshall error", err)
	}

	go deliver(data, appId)
}

func deliver(data []byte, appId string) {
	msg := amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            data,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	proxyId := "output.proxy." + appId
	err := proxyProducer.channel.Publish("infoExchange", proxyId, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
	}
	//if config.Verbose {
	//log.Println("SENDING PROXY data ", string(data))
	//}
}

func createProducer(name string) (*Producer, error) {
	p := NewProducer(name)

	if config.Verbose {
		log.Printf("creating connection for sending %s messages", p.name)
	}

	user := config.Current.Kontrold.RabbitMq.Login
	password := config.Current.Kontrold.RabbitMq.Password
	host := config.Current.Kontrold.RabbitMq.Host
	port := config.Current.Kontrold.RabbitMq.Port

	p.conn = amqputil.CreateAmqpConnection(user, password, host, port)
	p.channel = amqputil.CreateChannel(p.conn)

	return p, nil
}
