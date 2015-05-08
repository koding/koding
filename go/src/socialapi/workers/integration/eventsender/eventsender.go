package eventsender

import (
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"strconv"

	"labix.org/v2/mgo"

	"github.com/koding/cache"
	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	QueueLength     = 1
	SendMessageBody = "Welcome! This is your first message"
	StartCollBody   = "Keep partying with other developers."
	CreateWSBody    = "First rule of creating workspace is..."

	cacheSize = 10000

	sendMessageVersion = "v1"
	startCollVersion   = "v1"
	createWSVersion    = "v1"
)

var (
	ErrUserNotFound  = errors.New("user not found")
	sendMessageEvent = fmt.Sprintf("sendmessage %s", sendMessageVersion)
	startCollEvent   = fmt.Sprintf("startcollaboration %s", startCollVersion)
	createWSEvent    = fmt.Sprintf("createworkspace %s", createWSVersion)
)

type Controller struct {
	log       logging.Logger
	exporter  eventexporter.Exporter
	userCache cache.Cache
	env       string
}

type WorkspaceData struct {
	AccountId int64
}

func New(conf *config.Config, log logging.Logger) *Controller {
	exporter := eventexporter.NewSegmentIOExporter(conf.Segment, QueueLength)

	return &Controller{
		log:       log,
		exporter:  exporter,
		userCache: cache.NewLRU(cacheSize),
		env:       conf.Environment,
	}
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func (c *Controller) MessageCreated(cm *models.ChannelMessage) error {
	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return nil
	}

	event, err := c.prepareEvent(sendMessageEvent, cm.AccountId)
	if err != nil {
		return err
	}

	event.Properties["groupName"] = "koding"
	event.Properties["message"] = SendMessageBody

	return c.exporter.Send(event)
}

func (c *Controller) ChannelCreated(ch *models.Channel) error {
	if ch.TypeConstant != models.Channel_TYPE_COLLABORATION {
		return nil
	}

	event, err := c.prepareEvent(startCollEvent, ch.CreatorId)
	if err != nil {
		return err
	}

	event.Properties["groupName"] = "koding"
	event.Properties["message"] = StartCollBody

	return c.exporter.Send(event)
}

func (c *Controller) WorkspaceCreated(w *WorkspaceData) error {
	event, err := c.prepareEvent(createWSEvent, w.AccountId)
	if err != nil {
		return err
	}

	event.Properties["groupName"] = "koding"
	event.Properties["message"] = CreateWSBody

	return c.exporter.Send(event)
}

func (c *Controller) Close() error {
	return c.exporter.Close()
}

func (c *Controller) prepareEvent(eventName string, accountId int64) (*eventexporter.Event, error) {

	user, err := c.EmailById(accountId)
	if err != nil {
		return nil, err
	}

	u := &eventexporter.User{
		Username: user.Name,
		Email:    user.Email,
	}

	p := map[string]interface{}{}
	p["username"] = user.Name
	p["env"] = c.env

	return &eventexporter.Event{
		Name:       eventName,
		User:       u,
		Properties: p,
	}, nil
}

func (c *Controller) EmailById(id int64) (*mongomodels.User, error) {
	data, err := c.userCache.Get(strconv.FormatInt(id, 10))
	if err == nil {
		user, ok := data.(*mongomodels.User)
		if ok {
			return user, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	acc, err := models.Cache.Account.ById(id)
	if err != nil {
		return nil, err
	}

	user, err := modelhelper.GetUser(acc.Nick)
	if err == mgo.ErrNotFound {
		return nil, ErrUserNotFound
	}

	if err != nil {
		return nil, err
	}

	if err := c.userCache.Set(strconv.FormatInt(id, 10), user); err != nil {
		return nil, err
	}

	return user, nil
}
