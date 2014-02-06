package topicmodifier

import (
	"encoding/json"
	"koding/messaging/rabbitmq"
	"koding/tools/config"
	"github.com/streadway/amqp"
)

var (
	Done      chan error
	Consumer  *rabbitmq.Consumer
	Publisher *rabbitmq.Producer
	Conf      *config.Config
)

type Status string

const (
	DELETE            Status = "delete"
	MERGE             Status = "merge"
	TRY_COUNT_LIMIT   int    = 3
	EXCHANGE_NAME            = "topicModifierExchange"
	WORKER_QUEUE_NAME        = "topicModifierWorkerQueue"
)

type TagModifierData struct {
	TagId    string `json:"tagId"`
	Status   Status `json:"status"`
	TryCount int    `json:"tryCount"`
	Error    string `json:"error"`
}

func createConnections() {
	initConsumer()
	initPublisher()
	initGraphPublisher()
}

func ConsumeMessage(conf *config.Config) {
	log.Notice("Topic Modifier: Checking for message")
	Conf = conf
	createConnections()
	if err := Consumer.Get(messageConsumer); err != nil {
		log.Critical("%v", err)
	}
	Shutdown()
}

var messageConsumer = func(delivery amqp.Delivery) {
	Completed = false
	modifierData := &TagModifierData{}
	if err := json.Unmarshal([]byte(delivery.Body), modifierData); err != nil {
		log.Error("Wrong Post Format", err, delivery)
		delivery.Ack(false)
		return
	}

	var err error
	tagId := modifierData.TagId
	if tagId == "" {
		log.Error("Empty tag id")
		delivery.Ack(false)
		return
	}
	switch modifierData.Status {
	default:
		log.Error("Unknown modification status %s", modifierData.Status)
		delivery.Ack(false)
		return
	case DELETE:
		err = deleteTags(tagId)
	case MERGE:
		err = mergeTags(tagId)
	}

	if err != nil {
		modifierData.Error = err.Error()
	}

	finalize(delivery, modifierData)
}

func finalize(delivery amqp.Delivery, modifierData *TagModifierData) {
	// update is completed
	if Completed {
		log.Info("Merge Completed")
		delivery.Ack(false)
		Shutdown()
		return
	}

	// update is still ongoing. just requeue the message
	if modifierData.Error == "" {
		delivery.Nack(false, true)
		Shutdown()
		return
	}

	log.Error("Error in topic update process: %s.", modifierData.Error)
	modifierData.Error = ""
	modifierData.TryCount += 1
	// it has reached max try count. dropping the message
	if modifierData.TryCount == TRY_COUNT_LIMIT {
		log.Error("Reached Max Try Count for Tag: %s", modifierData.TagId)
		log.Error("Dropping message")
		delivery.Ack(false)
		Shutdown()
		return
	}

	if err := publish(Publisher, *modifierData); err != nil {
		log.Error("Publish error: %v", err)
		delivery.Nack(false, true)
	} else {
		delivery.Ack(false)
	}

	Shutdown()
}

func Shutdown() error {
	if Publisher != nil {
		log.Info("Closing Publisher Connection")
		Publisher.Shutdown()
		Publisher = nil
	}
	if GraphPublisher != nil {
		log.Info("Closing GraphPublisher Connection")
		GraphPublisher.Shutdown()
		GraphPublisher = nil
	}
	return nil
}

func initPublisher() {
	config := &PublisherConfig{
		ExchangeName: EXCHANGE_NAME,
		Tag:          "republishTopicModifier",
		RoutingKey:   "",
	}
	Publisher = createPublisher(config)
}

func initConsumer() {
	exchange := rabbitmq.Exchange{
		Name:    EXCHANGE_NAME,
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    WORKER_QUEUE_NAME,
		Durable: true,
	}

	binding := rabbitmq.BindingOptions{
		RoutingKey: "",
	}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: "TopicModifier",
	}

	var err error
	r := rabbitmq.New(Conf)
	Consumer, err = r.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		log.Error("%v", err)
		return
	}

	err = Consumer.QOS(3)
	if err != nil {
		panic(err)
	}
}
