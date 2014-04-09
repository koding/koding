package notification

import (
	"encoding/json"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
	"socialapi/models"
)

type Action func(*NotificationWorkerController, []byte) error

type NotificationWorkerController struct {
	routes  map[string]Action
	log     logging.Logger
	rmqConn *amqp.Connection
}

func (n *NotificationWorkerController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	n.log.Error("an error occured putting message back to queue", err)
	// multiple false
	// reque true
	delivery.Nack(false, true)
}

func NewNotificationWorkerController(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*NotificationWorkerController, error) {
	rmqConn, err := rmq.Connect("NewNotificationWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &NotificationWorkerController{
		log:     log,
		rmqConn: rmqConn.Conn(),
	}

	routes := map[string]Action{
		"channel_message_created": (*NotificationWorkerController).CreateReplyNotification,
		"interaction_created":   (*NotificationWorkerController).CreateInteractionNotification,
	}

	nwc.routes = routes

	return nwc, nil
}

// copy/paste
func (n *NotificationWorkerController) HandleEvent(event string, data []byte) error {
	n.log.Debug("New Event Received %s", event)
	handler, ok := n.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(n, data)
}

func (n *NotificationWorkerController) CreateReplyNotification(data []byte) error {
	cm, err := mapMessageToChannelMessage(data)
	if err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = cm.Id
	if err := models.CreateNotification(rn); err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	// hack it is
	if cm.InitialChannelId == 0 {
		if err := models.CreateNotification(rn); err != nil {
			return err
		}
	}


	// TODO send notification message to user
	return nil
}

func (n *NotificationWorkerController) CreateInteractionNotification(data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

	// a bit error prune since we take interaction type as notification type
	in := models.NewInteractionNotification(i.TypeConstant)
	in.TargetId = i.MessageId
	if err := models.CreateNotification(in); err != nil {
		return err
	}

	// TODO send notification message to user
	return nil
}

// copy/pasted from realtime package
func mapMessageToChannelMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

// copy/pasted from realtime package
func mapMessageToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}
