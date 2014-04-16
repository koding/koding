package notification

import (
	"encoding/json"
	"fmt"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
)

type Action func(*NotificationWorkerController, []byte) error

type NotificationWorkerController struct {
	routes          map[string]Action
	log             logging.Logger
	rmqConn         *amqp.Connection
	notifierRmqConn *amqp.Connection
}

type NotificationEvent struct {
	RoutingKey string                 `json:"routingKey"`
	Event      string                 `json:"event"`
	Content    map[string]interface{} `json:"content"`
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

	notifierRmqConn, err := rmq.Connect("NotifierWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &NotificationWorkerController{
		log:             log,
		rmqConn:         rmqConn.Conn(),
		notifierRmqConn: notifierRmqConn.Conn(),
	}

	routes := map[string]Action{
		"api.message_reply_created": (*NotificationWorkerController).CreateReplyNotification,
		"api.interaction_created":   (*NotificationWorkerController).CreateInteractionNotification,
		"api.notification_created":  (*NotificationWorkerController).NotifyUser,
		"api.notification_updated":  (*NotificationWorkerController).NotifyUser,
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
	mr, err := mapMessageToMessageReply(data)
	if err != nil {
		return err
	}

	// fetch replier
	cm := models.NewChannelMessage()
	cm.Id = mr.ReplyId
	if err := cm.Fetch(); err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = cm.AccountId

	if err := models.CreateNotification(rn); err != nil {
		return err
	}

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
	in.NotifierId = i.AccountId
	if err := models.CreateNotification(in); err != nil {
		return err
	}

	return nil
}

func (n *NotificationWorkerController) NotifyUser(data []byte) error {
	channel, err := n.notifierRmqConn.Channel()
	if err != nil {
		// change this with log
		return fmt.Errorf("channel connection error")
	}
	defer channel.Close()

	notification, err := mapMessageToNotification(data)
	if err != nil {
		return err
	}

	accountId := notification.AccountId
	oldAccount, err := fetchNotifierOldAccount(accountId)
	if err != nil {
		return err
	}

	// fetch user profile name from bongo as routing key
	ne := &NotificationEvent{}
	routingKey := oldAccount.Profile.Nickname

	// fetch notification content and get event type
	nc, err := notification.FetchContent()
	if err != nil {
		return err
	}

	ne.Event = nc.GetEventType()
	// add content later
	notificationMessage, err := json.Marshal(ne)
	if err != nil {
		return err
	}

	return channel.Publish(
		"notification",
		routingKey,
		false,
		false,
		amqp.Publishing{Body: notificationMessage},
	)
}

// fetchNotifierOldAccount fetches mongo account of a given new account id.
// this function must be used under another file for further use
func fetchNotifierOldAccount(accountId int64) (*mongomodels.Account, error) {
	newAccount := models.NewAccount()
	newAccount.Id = accountId
	if err := newAccount.Fetch(); err != nil {
		return nil, err
	}

	return modelhelper.GetAccountById(newAccount.OldId)

}

// copy/pasted from realtime package
func mapMessageToMessageReply(data []byte) (*models.MessageReply, error) {
	mr := models.NewMessageReply()
	if err := json.Unmarshal(data, mr); err != nil {
		return nil, err
	}

	return mr, nil
}

// copy/pasted from realtime package
func mapMessageToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}

func mapMessageToNotification(data []byte) (*models.Notification, error) {
	n := models.NewNotification()
	if err := json.Unmarshal(data, n); err != nil {
		return nil, err
	}

	return n, nil
}
