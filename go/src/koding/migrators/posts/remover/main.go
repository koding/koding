package main

import (
	"encoding/json"
	"flag"
	"fmt"
	helper "koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"os"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"

	"github.com/streadway/amqp"
	"labix.org/v2/mgo/bson"
)

var (
	Consumer    *rabbitmq.Consumer
	conf        *config.Config
	flagDebug   = flag.Bool("d", false, "Debug mode")
	flagProfile = flag.String("c", "", "Configuration profile from file")
	log         logging.Logger
)

type Migrator struct {
	Id           string `json:"id"`
	NewId        string `json:"newId"`
	PostType     string `json:"postType"`
	Status       string `json:"status"`
	Error        string `json:"error,omitempty"`
	ErrorCount   int    `json:"errorCount,omitempty"`
	SuccessCount int    `json:"successCount,omitempty"`
	Index        int
}

func main() {
	flag.Parse()
	if *flagProfile == "" {
		fmt.Println("Please specify profile via -c. Aborting.")
		return
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)

	log = logging.NewLogger("ElasticsearchFeeder")
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if *flagDebug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	log.Notice("Started Obsolete Post Remover")
	defer shutdown()
	initConsumer()
}

func initConsumer() {
	exchange := rabbitmq.Exchange{
		Name:    "MigratorExchange",
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    "MigratorQueue",
		Durable: true,
	}

	binding := rabbitmq.BindingOptions{
		RoutingKey: "",
	}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: "Migrator",
	}

	var err error
	rmqConf := &rabbitmq.Config{
		Host:     conf.Mq.Host,
		Port:     conf.Mq.Port,
		Username: conf.Mq.ComponentUser,
		Password: conf.Mq.Password,
		Vhost:    conf.Mq.Vhost,
	}
	r := rabbitmq.New(rmqConf, log)
	Consumer, err = r.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		panic(err)
	}

	err = Consumer.QOS(30000)
	if err != nil {
		panic(err)
	}
	Consumer.Consume(handler)
}

var handler = func(delivery amqp.Delivery) {
	migrator := &Migrator{}
	if err := json.Unmarshal([]byte(delivery.Body), migrator); err != nil {
		log.Error("Wrong Post Format", err, delivery)
		delivery.Ack(false)
		return
	}
	log.Notice("%d.", migrator.Index)
	var err error
	switch migrator.Status {
	case "Complete":
		err = deletePost(migrator)
		delivery.Ack(false)
	case "Incomplete":
		err = fmt.Errorf(migrator.Error)
		// delivery.Nack(false, true)
	}

	if err != nil {
		log.Error("%v %v is not migrated. Error: %v",
			migrator.PostType, migrator.Id, migrator.Error)
	}

}

func deletePost(m *Migrator) error {
	log.Info("Deleting %s with id: %s", m.PostType, m.Id)

	if err := deleteSourcePost(m); err != nil {
		return err
	}

	if err := deleteTargetPost(m); err != nil {
		return err
	}

	if err := deleteOpinions(m); err != nil {
		return err
	}

	if err := helper.DeletePostById(m.Id, m.PostType); err != nil {
		return err
	}

	log.Info("Post deleted")
	return nil
}

func deleteSourcePost(m *Migrator) error {
	relations := [4]string{"author", "tag", "commenter", "follower"}
	s := helper.Selector{
		"sourceName": m.PostType,
		"sourceId":   helper.GetObjectId(m.Id),
		"as":         helper.Selector{"$in": relations},
	}

	return helper.DeleteRelationships(s)
}

func deleteTargetPost(m *Migrator) error {
	relations := [2]string{"post", "creator"}
	s := helper.Selector{
		"targetName": m.PostType,
		"targetId":   helper.GetObjectId(m.Id),
		"as":         helper.Selector{"$in": relations},
	}

	return helper.DeleteRelationships(s)
}

func deleteOpinions(m *Migrator) error {
	if m.PostType != "JDiscussion" && m.PostType != "JTutorial" {
		return nil
	}

	// find opinions
	s := helper.Selector{
		"sourceId":   helper.GetObjectId(m.Id),
		"sourceName": m.PostType,
		"targetName": "JOpinion",
	}
	rels, err := helper.GetAllRelationships(s)
	if err != nil {
		return err
	}

	found := len(rels)
	log.Info("%d opinions(s) found", found)

	if found == 0 {
		return nil
	}

	ids := make([]bson.ObjectId, 0, found)
	for _, rel := range rels {
		ids = append(ids, rel.TargetId)
	}

	selector := helper.Selector{
		"sourceName": "JAccount",
		"as":         "creator",
		"targetName": "JOpinion",
		"targetId":   helper.Selector{"$in": ids},
	}
	if err := helper.DeleteRelationships(selector); err != nil {
		return nil
	}

	selector["sourceName"] = m.PostType
	selector["as"] = "opinion"
	if err := helper.DeleteRelationships(selector); err != nil {
		return nil
	}

	// remove opinions
	s = helper.Selector{
		"_id": helper.Selector{"$in": ids},
	}

	if err := helper.DeleteOpinion(s); err != nil {
		return err
	}
	log.Info("Removed opinion relationships")
	return nil
}

func shutdown() {
	Consumer.Shutdown()
}
