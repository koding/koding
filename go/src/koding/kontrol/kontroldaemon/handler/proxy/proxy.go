package proxy

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/kontrol/helper"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"log"
)

var proxyProducer *helper.Producer
var proxyConfig *proxyconfig.ProxyConfiguration

func Startup() {
	var err error
	proxyProducer, err = helper.CreateProducer("proxy")
	if err != nil {
		log.Println(err)
	}

	err = proxyProducer.Channel.ExchangeDeclare("infoExchange", "topic", true, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
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
		if config.Verbose {
			log.Println("got 'addProxy' json request")
		}
		err := proxyConfig.AddProxy(msg.Uuid)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addKey":
		if config.Verbose {
			log.Println("got 'addKey' json request")
		}
		err := proxyConfig.AddKey(msg.Username, msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid, msg.RabbitKey)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "addDomain":
		if config.Verbose {
			log.Println("got 'addDomain' json request")
		}
		err := proxyConfig.AddDomain(msg.Username, msg.DomainName, msg.ServiceName, msg.Key, msg.Host, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
		sendResponse("updateProxy", msg.Uuid)
	case "deleteProxy":
		if config.Verbose {
			log.Println("got 'deleteProxy' json request")
		}
		err := proxyConfig.DeleteProxy(msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteKey":
		if config.Verbose {
			log.Println("got 'deleteKey' json request")
		}
		err := proxyConfig.DeleteKey(msg.Username, msg.ServiceName, msg.Key, msg.Host, msg.HostData, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteServiceName":
		if config.Verbose {
			log.Println("got 'deleteServiceName' json request")
		}
		err := proxyConfig.DeleteServiceName(msg.Username, msg.ServiceName, msg.Uuid)
		if err != nil {
			log.Println(err)
		}
	case "deleteDomain":
		if config.Verbose {
			log.Println("got 'deleteDame' json request")
		}
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
		Priority:        0, // 0-9
	}

	proxyId := "output.proxy." + appId
	err := proxyProducer.Channel.Publish("infoExchange", proxyId, false, false, msg)
	if err != nil {
		log.Printf("error while publishing proxy message: %s", err)
	}
	//if config.Verbose {
	//log.Println("SENDING PROXY data ", string(data))
	//}
}
