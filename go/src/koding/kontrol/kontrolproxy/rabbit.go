package main

/* disable until we use this
import (
	"bufio"
	"bytes"
	"fmt"
	"github.com/streadway/amqp"
	"log"
	"net/http"
	"time"
)

type RabbitChannel struct {
	ReplyTo string
	Receive chan []byte
}

var amqpStream *AmqpStream
var connections = make(map[string]RabbitChannel)

func rabbitTransport(outreq *http.Request, userInfo *UserInfo, rabbitKey string) (*http.Response, error) {
	requestHost := outreq.Host
	output := new(bytes.Buffer)
	outreq.Host = outreq.URL.Host // WriteProxy overwrites outreq.URL.Host otherwise..

	err := outreq.WriteProxy(output)
	if err != nil {
		return nil, err
	}

	rabbitClient := userInfo.Domain.Proxy.Username + "-" + userInfo.Domain.Proxy.Servicename + "-" + rabbitKey

	if _, ok := connections[rabbitClient]; !ok {
		queue, err := amqpStream.channel.QueueDeclare("", false, true, true, false, nil)
		if err != nil {
			return nil, err
		}
		if err := amqpStream.channel.QueueBind("", "", "kontrol-rabbitproxy", false, nil); err != nil {
			return nil, err
		}
		messages, err := amqpStream.channel.Consume("", "", true, false, false, false, nil)
		if err != nil {
			return nil, err
		}

		connections[rabbitClient] = RabbitChannel{
			ReplyTo: queue.Name,
			Receive: make(chan []byte, 1),
		}

		go func() {
			for msg := range messages {
				log.Printf("got rabbit http message for %s", connections[rabbitClient].ReplyTo)
				connections[rabbitClient].Receive <- msg.Body
			}
		}()
	}

	fmt.Println("published http request to rabbit, waiting for request")
	msg := amqp.Publishing{
		ContentType: "text/plain",
		Body:        output.Bytes(),
		ReplyTo:     connections[rabbitClient].ReplyTo,
	}

	amqpStream.channel.Publish("kontrol-rabbitproxy", rabbitClient, false, false, msg)

	var respData []byte
	// why we don't use time.After: https://groups.google.com/d/msg/golang-dev/oZdV_ISjobo/5UNiSGZkrVoJ
	t := time.NewTimer(20 * time.Second)
	select {
	case respData = <-connections[rabbitClient].Receive:
	case <-t.C:
		fmt.Println("timeout. no rabbit proxy message receieved")
		return nil, fmt.Errorf("kontrolproxy could not connect to rabbit-client %s\n", requestHost)
	}
	t.Stop()

	if respData == nil {
		return nil, fmt.Errorf("status interal %d", http.StatusInternalServerError)
	}
	buf := bytes.NewBuffer(respData)
	respreader := bufio.NewReader(buf)

	// ok got now response from rabbit :)
	res, err := http.ReadResponse(respreader, outreq)
	if err != nil {
		return nil, err
	}

	return res, nil
}

*/
