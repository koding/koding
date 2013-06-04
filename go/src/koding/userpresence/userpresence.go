package main

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/tools/amqputil"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"strings"
	"time"
)

type socketIds map[string]bool

var (
	resourceName      string
	followFeedChannel *amqp.Channel
	socketIdsByUser   map[string]socketIds
	timersByUser      map[string]*time.Timer
)

func main() {

	var err error

	if followFeedChannel, err = createFollowFeedChannel("followfeed"); err != nil {
		panic(err)
	}

	mainAmqpConn := amqputil.CreateConnection("userpresence")

	resourceName = "users-presence"

	startMonitoring(mainAmqpConn)
	startControlling(mainAmqpConn)

	select {}
}

func startMonitoring(mainAmqpConn *amqp.Connection) {

	channel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

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

	users := mongo.GetCollection("jUsers")
	accounts := mongo.GetCollection("jAccounts")

	user, account := make(map[string]interface{}), make(map[string]interface{})

	if err := users.Find(bson.M{"username": username}).One(&user); err != nil {
		return err
	}
	if err := accounts.Find(bson.M{"profile.nickname": username}).One(&account); err != nil {
		return err
	}
	// update the user's actual status
	users.Update(
		bson.M{"_id": user["_id"]},
		bson.M{
			"$set": bson.M{
				"onlineStatus.actual": status,
			},
		},
	)

	onlineStatus := make(map[string]interface{})

	if user["onlineStatus"] != nil {
		onlineStatus = (user["onlineStatus"]).(map[string]interface{})
	}

	var publicStatus string

	if onlineStatus["userPreference"] == nil {
		publicStatus = status
	} else {
		publicStatus = onlineStatus["userPreference"].(string)
	}
	// update the user's public status
	accounts.Update(
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

func startControlling(mainAmqpConn *amqp.Connection) {

	socketIdsByUser = make(map[string]socketIds)
	timersByUser = make(map[string]*time.Timer)

	controlChannel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

	bindingChannel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

	resourceName := "users-presence-control"

	if err := controlChannel.ExchangeDeclare(
		resourceName, // exchange name
		"fanout",     // kind
		false,        // durable
		true,         // auto delete
		false,        // internal
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	if _, err := controlChannel.QueueDeclare(
		resourceName, // queue name
		false,        // durable
		true,         // auto delete
		true,         // exclusive
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	if err := controlChannel.QueueBind(
		resourceName, // queue name
		"",           // key
		resourceName, // exchange name
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := controlChannel.Consume(
		"",    // use the anonymous queue from above
		"",    // ctag
		true,  // no-ack
		false, // exclusive
		false, // no local
		false, // no wait
		nil,   // arguments
	)
	if err != nil {
		panic(err)
	}

	go handleControl(deliveries, bindingChannel, make(chan error))

}

func handleControl(
	deliveries <-chan amqp.Delivery,
	bindingChannel *amqp.Channel,
	done chan error,
) {
	for d := range deliveries {

		if d.RoutingKey != "auth.join" && d.RoutingKey != "auth.leave" {
			log.Printf("Consumed an invalid routing key: %s", d.RoutingKey)
			continue
		}

		msg := new(presenceControlMessage)
		json.Unmarshal(d.Body, &msg)

		var callee func(string, string, *amqp.Channel) error
		switch d.RoutingKey {
		case "auth.join":
			callee = handleAuthJoin
		case "auth.leave":
			callee = handleAuthLeave
		}

		if msg.Username == "" || msg.SocketId == "" {
			log.Printf("Invalid message: username: %s socketId: %s", msg.Username, msg.SocketId)
			continue
		}

		if err := callee(msg.Username, msg.SocketId, bindingChannel); err != nil {
			log.Printf("An error occurred: %v", err)
		}

	}
	log.Printf("handle: deliveries channel closed")
	done <- nil
}

func handleAuthJoin(username, socketId string, bindingChannel *amqp.Channel) error {

	if _, ok := socketIdsByUser[username]; !ok {
		socketIdsByUser[username] = make(socketIds)
	}

	if socketIdsByUser[username][socketId] != true {
		socketIdsByUser[username][socketId] = true
		if len(socketIdsByUser[username]) == 1 {
			if err := addPresenceBinding(username, bindingChannel); err != nil {
				return err
			}
		}
	}

	log.Print(socketIdsByUser)
	return nil
}

func handleAuthLeave(username, socketId string, bindingChannel *amqp.Channel) error {

	if _, ok := socketIdsByUser[username]; !ok {
		return nil
	}

	delete(socketIdsByUser[username], socketId)

	if len(socketIdsByUser[username]) == 0 {
		if err := removePresenceBinding(username, bindingChannel); err != nil {
			return err
		}
		delete(socketIdsByUser, username)
	}

	log.Print(socketIdsByUser)
	return nil
}

type presenceControlMessage struct {
	Username string
	SocketId string
}

func addPresenceBinding(username string, bindingChannel *amqp.Channel) error {
	if _, ok := timersByUser[username]; ok {
		timersByUser[username].Stop()
		delete(timersByUser, username)
	}
	return bindingChannel.QueueBind(
		username,     // queue name
		username,     // key
		resourceName, // exchange name
		false,        // no wait
		nil,          // arguments
	)
}

func removePresenceBinding(username string, bindingChannel *amqp.Channel) error {
	if _, ok := timersByUser[username]; !ok {
		timersByUser[username] = time.NewTimer(time.Second * 10)
	}
	select {
	case <-timersByUser[username].C:
		return bindingChannel.QueueUnbind(
			username,     // queue name
			username,     // key
			resourceName, // exchange name
			nil,          // arguments
		)
	}
	return nil
}
