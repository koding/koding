package main

import (
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/tools/amqputil"
	"labix.org/v2/mgo/bson"
	"log"
)

func main() {
	startMonitoring()
}

func startMonitoring() {
	amqpConn := amqputil.CreateConnection("userpresence")

	channel, err := amqpConn.Channel()
	if err != nil {
		panic(err)
	}

	resourceName := "users-presence"

	channel.ExchangeDeclare(
		resourceName, // the exchange name
		"x-presence", // use the presence exchange plugin
		false,        // durable
		true,         // autodelete
		false,        // internal
		false,        // no wait
		nil,          // arguments
	)
	channel.QueueDeclare(
		resourceName, // the queue name
		false,        // durable
		true,         // autodelete
		true,         // exclusive
		false,        // no wait
		nil,          // arguments
	)
	channel.QueueBind(
		resourceName, // queue name
		"",           // binding key (use an empty key to monitor messages)
		resourceName, // exchange name
		false,        // no wait
		nil,          // arguments
	)
	deliveries, err := channel.Consume(
		resourceName, // queue name
		"",           // ctag
		false,        // auto-ack
		false,        // exlusive
		false,        // no local
		false,        // no wait
		nil,          // arguments
	)
	go handle(deliveries, make(chan error))
	select {}
}

func handleJoin(username string) error {
	userCollection := mongo.GetCollection("jUsers")
	accountCollection := mongo.GetCollection("jAccounts")
	user := make(map[string]interface{})
	account := make(map[string]interface{})
	if err := userCollection.Find(bson.M{"username": username}).One(&user); err != nil {
		return err
	}
	if err := accountCollection.Find(bson.M{"profile.nickname": username}).One(&account); err != nil {
		return err
	}
	log.Printf("%s: %v %v", user, account)
	return nil
}

func handleLeave(user string) error {
	log.Println(user + " has left")
	return nil
}

func handle(deliveries <-chan amqp.Delivery, done chan error) {
	for d := range deliveries {
		action, user := d.Headers["action"], d.Headers["key"].(string)
		log.Printf("%v %v", action, user)
		var err error
		switch action {
		case "bind":
			err = handleJoin(user)
		case "unbind":
			err = handleLeave(user)
		}
		if err != nil {
			done <- err
		}
	}
	log.Printf("handle: deliveries channel closed")
	done <- nil
}
