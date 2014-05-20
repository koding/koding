package emailnotifier

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	socialmodels "socialapi/models"
	"socialapi/workers/notification/models"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/sendgrid/sendgrid-go"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
)

type Action func(*EmailNotifierWorkerController, []byte) error

type EmailNotifierWorkerController struct {
	routes   map[string]Action
	log      logging.Logger
	rmqConn  *amqp.Connection
	settings *EmailSettings
}

type EmailSettings struct {
	Username string
	Password string
	FromName string
	FromMail string
}

func (n *EmailNotifierWorkerController) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Nack(false, false)

	return false
}

func (n *EmailNotifierWorkerController) HandleEvent(event string, data []byte) error {
	n.log.Debug("New Event Received %s", event)
	handler, ok := n.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(n, data)
}

func NewEmailNotifierWorkerController(rmq *rabbitmq.RabbitMQ, log logging.Logger, es *EmailSettings) (*EmailNotifierWorkerController, error) {
	rmqConn, err := rmq.Connect("NewEmailNotifierWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &EmailNotifierWorkerController{
		log:      log,
		rmqConn:  rmqConn.Conn(),
		settings: es,
	}

	routes := map[string]Action{
		"notification.notification_created": (*EmailNotifierWorkerController).SendInstantEmail,
		"notification.notification_updated": (*EmailNotifierWorkerController).SendInstantEmail,
	}

	nwc.routes = routes

	return nwc, nil
}

func (n *EmailNotifierWorkerController) SendInstantEmail(data []byte) error {
	channel, err := n.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	notification := models.NewNotification()
	if err := notification.MapMessage(data); err != nil {
		return err
	}

	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	// do not notify actor for her own action
	if activity.ActorId == notification.AccountId {
		return nil
	}

	// do not notify user when notification is not yet activated
	if notification.ActivatedAt.IsZero() {
		return nil
	}

	uc, err := fetchUserContact(notification.AccountId)
	if err != nil {
		return fmt.Errorf("an error occurred while fetching user contact: %s", err)
	}

	target := socialmodels.NewChannelMessage()
	if err := target.ById(nc.TargetId); err != nil {
		return fmt.Errorf("target message not found")
	}

	container := &NotificationContainer{
		Activity:     activity,
		Content:      nc,
		Notification: notification,
		Slug:         target.Slug,
	}
	container.Message = n.fetchContentBody(nc, target)
	contentType, err := nc.GetContentType()
	if err != nil {
		return err
	}
	contentType.SetActorId(target.AccountId)
	contentType.SetListerId(notification.AccountId)
	container.ActivityMessage = contentType.GetActivity()

	body, err := renderTemplate(uc, container)
	if err != nil {
		return fmt.Errorf("an error occurred while preparing notification email: %s", err)
	}
	subject := prepareSubject(container)

	return n.SendMail(uc, body, subject)
}

type UserContact struct {
	Email     string
	FirstName string
	LastName  string
	Username  string
	Hash      string
}

func prepareSlug(container *NotificationContainer, cm *socialmodels.ChannelMessage) {
	switch cm.TypeConstant {
	case socialmodels.ChannelMessage_TYPE_POST:
		container.Slug = cm.Slug
	case socialmodels.ChannelMessage_TYPE_REPLY:
		// TODO we need append something like comment id to parent message slug
		container.Slug = fetchRepliedMessage(cm.Id).Slug
	}
}

func prepareObjectType(container *NotificationContainer, cm *socialmodels.ChannelMessage) {
	switch cm.TypeConstant {
	case socialmodels.ChannelMessage_TYPE_POST:
		container.ObjectType = "status update"
	case socialmodels.ChannelMessage_TYPE_REPLY:
		container.ObjectType = "comment"
	}
}

func fetchUserContact(accountId int64) (*UserContact, error) {
	a := socialmodels.NewAccount()
	if err := a.ById(accountId); err != nil {
		return nil, err
	}

	account, err := modelhelper.GetAccountById(a.OldId)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("old account not found")
		}

		return nil, err
	}

	user, err := modelhelper.GetUser(account.Profile.Nickname)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("user not found")
		}

		return nil, err
	}

	uc := &UserContact{
		Email:     user.Email,
		FirstName: account.Profile.FirstName,
		LastName:  account.Profile.LastName,
		Username:  account.Profile.Nickname,
		Hash:      account.Profile.Hash,
	}

	return uc, nil
}

func (n *EmailNotifierWorkerController) fetchContentBody(nc *models.NotificationContent, cm *socialmodels.ChannelMessage) string {

	switch nc.TypeConstant {
	case models.NotificationContent_TYPE_LIKE:
		return cm.Body
	case models.NotificationContent_TYPE_MENTION:
		return fetchLastReplyBody(cm.Id)
	case models.NotificationContent_TYPE_COMMENT:
		return fetchLastReplyBody(cm.Id)
	}

	return ""
}

func fetchLastReplyBody(targetId int64) string {
	mr := socialmodels.NewMessageReply()
	mr.MessageId = targetId
	query := socialmodels.NewQuery()
	query.Limit = 1
	messages, err := mr.List(query)
	if err != nil {
		return ""
	}

	if len(messages) == 0 {
		return ""
	}

	return messages[0].Body
}

func fetchRepliedMessage(replyId int64) *socialmodels.ChannelMessage {
	mr := socialmodels.NewMessageReply()
	mr.ReplyId = replyId

	parent, err := mr.FetchRepliedMessage()
	if err != nil {
		parent = socialmodels.NewChannelMessage()
	}

	return parent
}

func (n *EmailNotifierWorkerController) SendMail(uc *UserContact, body, subject string) error {
	es := n.settings
	sg := sendgrid.NewSendGridClient(es.Username, es.Password)
	fullname := fmt.Sprintf("%s %s", uc.FirstName, uc.LastName)

	message := sendgrid.NewMail()
	message.AddTo(uc.Email)
	message.AddToName(fullname)
	message.SetSubject(subject)
	message.SetHTML(body)
	message.SetFrom(es.FromMail)
	message.SetFromName(es.FromName)

	if err := sg.Send(message); err != nil {
		return fmt.Errorf("an error occurred while sending notification email to %s", uc.Username)
	}
	n.log.Info("%s notified by email", uc.Username)

	return nil
}
