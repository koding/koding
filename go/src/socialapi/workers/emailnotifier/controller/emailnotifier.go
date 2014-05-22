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
	"github.com/robfig/cron"
	"github.com/sendgrid/sendgrid-go"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const SCHEDULE = "0 0 0 * * *"

var cronJob *cron.Cron

var emailConfig = map[string]string{
	models.NotificationContent_TYPE_COMMENT: "comment",
	models.NotificationContent_TYPE_LIKE:    "likeActivities",
	models.NotificationContent_TYPE_FOLLOW:  "followActions",
	models.NotificationContent_TYPE_JOIN:    "groupJoined",
	models.NotificationContent_TYPE_LEAVE:   "groupLeft",
	models.NotificationContent_TYPE_MENTION: "mention",
}

type Action func(*Controller, []byte) error

type Controller struct {
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

func (n *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	n.log.Error("an error occured: %s", err)
	delivery.Ack(false)

	return false
}

func (n *Controller) HandleEvent(event string, data []byte) error {
	n.log.Debug("New Event Received %s", event)
	handler, ok := n.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(n, data)
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger, es *EmailSettings) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewEmailNotifierWorkerController")
	if err != nil {
		return nil, err
	}

	nwc := &Controller{
		log:      log,
		rmqConn:  rmqConn.Conn(),
		settings: es,
	}

	routes := map[string]Action{
		"notification.notification_created": (*Controller).SendInstantEmail,
		"notification.notification_updated": (*Controller).SendInstantEmail,
	}

	nwc.routes = routes

	nwc.initDailyEmailCron()

	return nwc, nil
}

func (n *EmailNotifierWorkerController) initDailyEmailCron() {

	cronJob = cron.New()
	cronJob.AddFunc(SCHEDULE, n.sendDailyMails)
	cronJob.Start()
}

func (n *Controller) SendInstantEmail(data []byte) error {
	channel, err := n.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	notification := models.NewNotification()
	if err := notification.MapMessage(data); err != nil {
		return err
	}

	// fetch latest activity for checking actor
	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	if !validNotification(activity, notification) {
		return nil
	}

	uc, err := fetchUserContact(notification.AccountId)
	if err != nil {
		return fmt.Errorf("an error occurred while fetching user contact: %s", err)
	}

	if !checkMailSettings(uc, nc) {
		return nil
	}

	container, err := buildContainer(activity, nc, notification)
	if err != nil {
		return err
	}

	body, err := renderTemplate(uc, container)
	if err != nil {
		return fmt.Errorf("an error occurred while preparing notification email: %s", err)
	}
	subject := prepareSubject(container)

	if err := createToken(uc, nc, container.Token); err != nil {
		return err
	}

	return n.SendMail(uc, body, subject)
}

type UserContact struct {
	AccountId     int64
	UserOldId     bson.ObjectId
	Email         string
	FirstName     string
	LastName      string
	Username      string
	Hash          string
	Token         string
	EmailSettings map[string]bool
}

func validNotification(a *models.NotificationActivity, n *models.Notification) bool {
	// do not notify actor for her own action
	if a.ActorId == n.AccountId {
		return false
	}

	// do not notify user when notification is not yet activated
	return !n.ActivatedAt.IsZero()
}

func checkMailSettings(uc *UserContact, nc *models.NotificationContent) bool {
	// notifications are disabled
	if val := uc.EmailSettings["global"]; !val {
		return false
	}

	// daily notifications are enabled
	if val := uc.EmailSettings["daily"]; val {
		return false
	}

	// get config
	return uc.EmailSettings[emailConfig[nc.TypeConstant]]
}

func buildContainer(accountId int64, a *models.NotificationActivity,
	nc *models.NotificationContent) (*NotificationContainer, error) {

	// if content type not valid return
	contentType, err := nc.GetContentType()
	if err != nil {
		return nil, err
	}

	container := &NotificationContainer{
		Activity:  a,
		Content:   nc,
		AccountId: accountId,
	}

	// if notification target is related with an object (comment/status update)
	if containsObject(nc) {
		target := socialmodels.NewChannelMessage()
		if err := target.ById(nc.TargetId); err != nil {
			return nil, fmt.Errorf("target message not found")
		}

		prepareGroup(container, target)
		prepareSlug(container, target)
		prepareObjectType(container, target)
		container.Message = fetchContentBody(nc, target)
		contentType.SetActorId(target.AccountId)
		contentType.SetListerId(accountId)
	}

	container.ActivityMessage = contentType.GetActivity()

	return container, nil
}

func prepareGroup(container *NotificationContainer, cm *socialmodels.ChannelMessage) {
	c := socialmodels.NewChannel()
	if err := c.ById(cm.InitialChannelId); err != nil {
		return
	}
	// TODO fix these Slug and Name
	container.Group = GroupContent{
		Slug: c.GroupName,
		Name: c.GroupName,
	}
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

// fetchUserContact gets user and account details with given account id
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

	token, err := generateToken()
	if err != nil {
		return nil, err
	}

	uc := &UserContact{
		AccountId:     accountId,
		UserOldId:     user.ObjectId,
		Email:         user.Email,
		FirstName:     account.Profile.FirstName,
		LastName:      account.Profile.LastName,
		Username:      account.Profile.Nickname,
		Hash:          account.Profile.Hash,
		EmailSettings: user.EmailFrequency,
		Token:         token,
	}

	return uc, nil
}

func containsObject(nc *models.NotificationContent) bool {
	return nc.TypeConstant == models.NotificationContent_TYPE_LIKE ||
		nc.TypeConstant == models.NotificationContent_TYPE_MENTION ||
		nc.TypeConstant == models.NotificationContent_TYPE_COMMENT
}

func fetchContentBody(nc *models.NotificationContent, cm *socialmodels.ChannelMessage) string {

	switch nc.TypeConstant {
	case models.NotificationContent_TYPE_LIKE:
		return cm.Body
	case models.NotificationContent_TYPE_MENTION:
		return cm.Body
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

func (n *Controller) SendMail(uc *UserContact, body, subject string) error {
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
