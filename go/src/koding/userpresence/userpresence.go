package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/db/mongodb"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/logger"
	"strings"
	"time"

	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	log         = logger.New("userpresence")
	mongo       *mongodb.MongoDB
	conf        *config.Config
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
)

type socketIds map[string]bool

var (
	resourceName          string
	followFeedAmqpChannel *amqp.Channel
	socketIdsByUser       map[string]socketIds
	timersByUser          map[string]*time.Timer
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*flagProfile)
	mongo = mongodb.NewMongoDB(conf.Mongo)
	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig("userpresence", *flagProfile)
	}
	log.SetLevel(logLevel)

	var err error

	if followFeedAmqpChannel, err = createFollowFeedChannel("followfeed"); err != nil {
		panic(err)
	}

	mainAmqpConn := amqputil.CreateConnection(conf, "userpresence")

	resourceName = "users-presence"

	startMonitoring(mainAmqpConn)
	startControlling(mainAmqpConn)
}

func startMonitoring(mainAmqpConn *amqp.Connection) {
	channel, err := mainAmqpConn.Channel()
	if err != nil {
		panic(err)
	}

	queueName := resourceName + conf.Version

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
		queueName, // the queue name
		false,     // durable
		true,      // autodelete
		true,      // exclusive
		false,     // no wait
		nil,       // arguments
	); err != nil {
		panic(err)
	}

	if err := channel.QueueBind(
		queueName,    // queue name
		"",           // binding key (use an empty key to monitor messages)
		resourceName, // exchange name
		false,        // no wait
		nil,          // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := channel.Consume(
		queueName, // queue name
		"",        // ctag
		true,      // auto-ack
		false,     // exlusive
		false,     // no local
		false,     // no wait
		nil,       // arguments
	)
	if err != nil {
		panic(err)
	}

	go handlePresence(deliveries, mainAmqpConn, make(chan error))

}

func handlePresence(
	deliveries <-chan amqp.Delivery,
	mainAmqpConn *amqp.Connection,
	done chan error,
) {
	channel, err := mainAmqpConn.Channel()
	if err != nil {
		done <- err
	}
	defer channel.Close()

	for d := range deliveries {
		action, username := d.Headers["action"].(string), d.Headers["key"].(string)
		// log.Printf("%v %v", action, username)
		var err error
		switch action {
		case "bind":
			err = updateOnlineStatus(channel, username, "online")
		case "unbind":
			err = updateOnlineStatus(channel, username, "offline")
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
	log.Info("handle: deliveries channel closed")
	done <- nil
}

func createFollowFeedChannel(component string) (*amqp.Channel, error) {

	conn, err := amqp.Dial(amqp.URI{
		Scheme:   "amqp",
		Host:     conf.FollowFeed.Host,
		Port:     conf.FollowFeed.Port,
		Username: strings.Replace(conf.FollowFeed.ComponentUser, "<component>", component, 1),
		Password: conf.FollowFeed.Password,
		Vhost:    conf.FollowFeed.Vhost,
	}.String())

	if err != nil {
		return nil, err
	}

	return conn.Channel()
}

func updateOnlineStatus(channel *amqp.Channel, username, status string) error {
	log.Info("Username: %v", username)

	user, account := make(bson.M), make(bson.M)

	userQuery := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}
	if err := mongo.Run("jUsers", userQuery); err != nil {
		return err
	}

	accountQuery := func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}
	if err := mongo.Run("jAccounts", accountQuery); err != nil {
		return err
	}

	userUpdateQuery := func(c *mgo.Collection) error {
		c.Update(
			bson.M{"_id": user["_id"]},
			bson.M{"$set": bson.M{"onlineStatus.actual": status}},
		)
		return nil
	}
	mongo.Run("jUsers", userUpdateQuery)

	onlineStatus := make(bson.M)

	if user["onlineStatus"] != nil {
		onlineStatus = user["onlineStatus"].(bson.M)
	}

	var publicStatus string

	if onlineStatus["userPreference"] == nil {
		publicStatus = status
	} else {
		publicStatus = onlineStatus["userPreference"].(string)
	}

	update := bson.M{"$set": bson.M{"onlineStatus": publicStatus}}
	accountUpdateQuery := func(c *mgo.Collection) error {
		c.Update(
			bson.M{"_id": account["_id"]},
			update,
		)
		return nil
	}
	mongo.Run("jAccounts", accountUpdateQuery)

	if err := broadcastStatusChange(channel, account, &update); err != nil {
		return err
	}

	return nil
}

func broadcastStatusChange(
	channel *amqp.Channel,
	account map[string]interface{},
	update *bson.M,
) error {
	oid := account["_id"].(bson.ObjectId)
	routingKey := "oid." + oid.Hex() + ".event.updateInstance"

	message, err := json.Marshal(update)
	if err != nil {
		return err
	}

	updateArr := make([]string, 1)
	updateArr[0] = fmt.Sprintf("%s", string(message))

	msg, err := json.Marshal(updateArr)
	if err != nil {
		return err
	}

	channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	)
	return nil
}

func changeFollowFeedExchangeBindings(username, action string) error {
	if err := followFeedAmqpChannel.ExchangeDeclare(
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

	if _, err := followFeedAmqpChannel.QueueDeclare(
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
		if err := followFeedAmqpChannel.QueueBind(
			username, // queue name
			username, // key
			username, // exchange name
			false,    // no wait
			nil,      // arguments
		); err != nil {
			return err
		}
	case "unbind":
		if err := followFeedAmqpChannel.QueueUnbind(
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

	handleControl(deliveries, mainAmqpConn, make(chan error))

}

func handleControl(
	deliveries <-chan amqp.Delivery,
	mainAmqpConn *amqp.Connection,
	done chan error,
) {

	bindingChannel, err := mainAmqpConn.Channel()
	if err != nil {
		done <- err
	}
	defer bindingChannel.Close()

	for d := range deliveries {

		if d.RoutingKey != "auth.join" && d.RoutingKey != "auth.leave" {
			log.Info("Consumed an invalid routing key: %s", d.RoutingKey)
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
			log.Error("Invalid message: username: %s socketId: %s", msg.Username, msg.SocketId)
			continue
		}

		if err := callee(msg.Username, msg.SocketId, bindingChannel); err != nil {
			log.Error("An error occurred: %v", err)
		}

	}
	log.Info("handle: deliveries channel closed")
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

	if _, err := bindingChannel.QueueDeclare(
		username, // queue name
		false,    // durable
		true,     // auto delete
		false,    // exclusive
		false,    // no wait
		nil,      // arguments
	); err != nil {
		return err
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
		if err := bindingChannel.QueueUnbind(
			username,     // queue name
			username,     // key
			resourceName, // exchange name
			nil,          // arguments
		); err != nil {
			return err
		}

		bindingChannel.QueueDelete(
			username, // queue name
			false,    // if unused
			false,    // if empty
			false,    // no wait
		)
	}
	return nil
}
