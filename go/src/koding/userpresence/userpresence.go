package main

import (
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/tools/amqputil"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"strings"
)

var followFeedChannel *amqp.Channel

func main() {

	var err error

	if followFeedChannel, err = createFollowFeedChannel("followfeed"); err != nil {
		panic(err)
	}

	mainAmqpConn := amqputil.CreateConnection("userpresence")

	startMonitoring(mainAmqpConn)
	startControlling(mainAmqpConn)

	select {}
}

func startControlling(mainAmqpConn *amqp.Connection) {

	channel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

	exchangeName := "users-presence-control"

	if err := channel.ExchangeDeclare(
		exchangeName, // exchange name
		"fanout",     // kind
		false,        // durable
		true,         // auto delete
		false,        // internal
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	if _, err := channel.QueueDeclare(
		"",    // queue name
		false, // durable
		true,  // auto delete
		true,  // exclusive
		false, // no wait
		nil,   // arguments
	); err != nil {
		panic(err)
	}

	if err := channel.QueueBind(
		"",           // queue name
		"",           // key
		exchangeName, // exchange name
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := channel.Consume(
		"",    // use the anonymous queue from above
		"",    // ctag
		false, // no-ack
		false, // exclusive
		false, // no local
		false, // no wait
		nil,   // arguments
	)
	if err != nil {
		panic(err)
	}

	go handleControl(deliveries, make(chan error))

}

func startMonitoring(mainAmqpConn *amqp.Connection) {

	channel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

	resourceName := "users-presence"

	if err := channel.ExchangeDeclare(
		resourceName, // the exchange name
		"x-presence", // use the presence exchange plugin
		false,        // durable
		true,         // autodelete
		false,        // internal
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	if _, err := channel.QueueDeclare(
		resourceName, // the queue name
		false,        // durable
		true,         // autodelete
		true,         // exclusive
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	if err := channel.QueueBind(
		resourceName, // queue name
		"",           // binding key (use an empty key to monitor messages)
		resourceName, // exchange name
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := channel.Consume(
		resourceName, // queue name
		"",           // ctag
		false,        // no-ack
		false,        // exlusive
		false,        // no local
		false,        // no wait
		nil,          // arguments
	)
	if err != nil {
		panic(err)
	}

	go handlePresence(deliveries, make(chan error))

}

func createFollowFeedChannel(component string) (*amqp.Channel, error) {
	conn, err := amqp.Dial(amqp.URI{
		Scheme:   "amqp",
		Host:     config.Current.FollowFeed.Host,
		Port:     config.Current.FollowFeed.Port,
		Username: strings.Replace(config.Current.FollowFeed.ComponentUser, "<component>", component, 1),
		Password: config.Current.FollowFeed.Password,
		Vhost:    config.Current.FollowFeed.Vhost,
	}.String())

	if err != nil {
		return nil, err
	}

	return conn.Channel()
}

func updateOnlineStatus(username, status string) error {
	userCollection := mongo.GetCollection("jUsers")
	accountCollection := mongo.GetCollection("jAccounts")

	user, account := make(map[string]interface{}), make(map[string]interface{})

	if err := userCollection.Find(bson.M{"username": username}).One(&user); err != nil {
		return err
	}
	if err := accountCollection.Find(bson.M{"profile.nickname": username}).One(&account); err != nil {
		return err
	}
	// update the user's actual status
	userCollection.Update(
		bson.M{"_id": user["_id"]},
		bson.M{
			"$set": bson.M{
				"onlineStatus.actual": status,
			},
		},
	)

	onlineStatus := make(map[string]string)
	if user["onlineStatus"] == nil {
		onlineStatus = user["onlineStatus"].(map[string]string)
	}

	var publicStatus string

	if onlineStatus["userPreference"] == "" {
		publicStatus = status
	} else {
		publicStatus = onlineStatus["userPreference"]
	}
	// update the user's public status
	accountCollection.Update(
		bson.M{"_id": account["_id"]},
		bson.M{
			"$set": bson.M{
				"onlineStatus": publicStatus,
			},
		},
	)

	return nil
}

func changeFollowFeedExchangeBindings(username, action string) error {
	if err := followFeedChannel.ExchangeDeclare(
		username, // exchange name
		"topic",  // kind
		false,    // durable
		false,    // auto delete
		false,    // internal
		false,    // no wait
		nil,      // arguments
	); err != nil {
		return err
	}

	if _, err := followFeedChannel.QueueDeclare(
		username, // queue name
		false,    // durable
		true,     // auto delete
		false,    // exclusive
		false,    // no wait
		nil,      // arguments
	); err != nil {
		return err
	}

	switch action {
	case "bind":
		if err := followFeedChannel.QueueBind(
			username, // queue name
			username, // key
			username, // exchange name
			false,    // no wait
			nil,      // arguments
		); err != nil {
			return err
		}
	case "unbind":
		if err := followFeedChannel.QueueUnbind(
			username, // queue name
			username, // key
			username, // exchange name
			nil,      // arguments
		); err != nil {
			return err
		}
	}
	return nil
}

func handlePresence(deliveries <-chan amqp.Delivery, done chan error) {
	for d := range deliveries {
		action, username := d.Headers["action"].(string), d.Headers["key"].(string)
		log.Printf("%v %v", action, username)
		var err error
		switch action {
		case "bind":
			err = updateOnlineStatus(username, "online")
		case "unbind":
			err = updateOnlineStatus(username, "offline")
		}
		if err != nil {
			done <- err
			continue
		}
		err = changeFollowFeedExchangeBindings(username, action)
		if err != nil {
			done <- err
		}
	}
	log.Printf("handle: deliveries channel closed")
	done <- nil
}

func handleControl(deliveries <-chan amqp.Delivery, done chan error) {
	for d := range deliveries {
		log.Printf(
			"got %dB delivery: [%v] %q",
			len(d.Body),
			d.DeliveryTag,
			d.Body,
		)
	}
	log.Printf("handle: deliveries channel closed")
	done <- nil
}
