package proxy

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/kontrol/kontrolhelper"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"log"
)

var proxyProducer *kontrolhelper.Producer
var proxyConfig *proxyconfig.ProxyConfiguration

func Startup() {
	var err error
	proxyProducer, err = kontrolhelper.CreateProducer("proxy")
	if err != nil {
		log.Println(err)
	}

	err = proxyProducer.Channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatalf("exchange.declare: %s", err)
	}

	proxyConfig, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}

	log.Println("kontrold proxy plugin is initialized")
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
	case "addUser":
		log.Println("got 'addUser' json request")
		err := proxyConfig.AddUser(msg.Uuid, msg.Username)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addKey":
		log.Println("got 'addKey' json request")
		err := proxyConfig.AddKey(msg.Username, msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid, msg.RabbitKey)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addRule":
		log.Println("got 'addRule' json request")
		err := proxyConfig.AddRule(msg.Uuid, msg.Username, msg.ServiceName, msg.IpRegex, msg.Countries)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addDomain":
		log.Println("got 'addDomain' json request")
		err := proxyConfig.AddDomain(msg.Username, msg.DomainName, msg.ServiceName, msg.Key, msg.Host, msg.Uuid)
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
		err := proxyConfig.DeleteKey(msg.Username, msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteServiceName":
		log.Println("got 'deleteServiceName' json request")
		err := proxyConfig.DeleteServiceName(msg.Username, msg.ServiceName, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteDomain":
		log.Println("got 'deleteDame' json request")
		err := proxyConfig.DeleteDomain(msg.DomainName, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	default:
		log.Println("invalid doProxy action", msg.Action)
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
	}

	proxyId := "output.proxy." + appId
	err := proxyProducer.Channel.Publish("infoExchange", proxyId, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
	}
}
