package eventsender

import (
	"errors"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"strconv"

	"gopkg.in/mgo.v2"

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
)

var (
	ErrUserNotFound = errors.New("user not found")
	ErrDisabled     = errors.New("feature disabled")

	sendMessageEvent = "sendmessage"
	startCollEvent   = "startcollaboration"
	createWSEvent    = "createworkspace"
)

type Controller struct {
	log          logging.Logger
	exporter     eventexporter.Exporter
	userCache    cache.Cache
	accountCache cache.Cache
	env          string
	isDisabled   bool
}

type WorkspaceData struct {
	AccountId int64 `json:"accountId,string"`
	GroupName string
}

func New(conf *config.Config, log logging.Logger) *Controller {
	exporter := eventexporter.NewSegmentIOExporter(conf.Segment, QueueLength)

	return &Controller{
		log:          log,
		exporter:     exporter,
		userCache:    cache.NewLRU(cacheSize),
		accountCache: cache.NewLRU(cacheSize),
		env:          conf.Environment,
		isDisabled:   conf.DisabledFeatures.BotChannel,
	}
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

// MessageCreated sends an event to Iterable, when a new post is created.
// In 'send message' workflow, we are intercepting these events. Depending on
// this, when it is user's first message, Iterable is calling our webhook for
// creating bot messages
func (c *Controller) MessageCreated(cm *models.ChannelMessage) error {
	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return nil
	}

	event, err := c.prepareEvent(sendMessageEvent, cm.AccountId)
	if err == ErrDisabled {
		return nil
	}

	if err != nil {
		return err
	}

	groupChannel, err := cm.FetchParentChannel()
	if err != nil {
		return err
	}

	event.Properties["groupName"] = groupChannel.GroupName
	event.Properties["message"] = SendMessageBody

	return c.exporter.Send(event)
}

// ChannelCreated sends an event to Iterable, when a new collaboration channel
// is created. In 'start collaboration' workflow, we are intercepting these events.
// Depending on this, when it is user's first collaboration channel,
// Iterable is calling our webhook for creating bot messages
func (c *Controller) ChannelCreated(ch *models.Channel) error {
	if ch.TypeConstant != models.Channel_TYPE_COLLABORATION {
		return nil
	}

	event, err := c.prepareEvent(startCollEvent, ch.CreatorId)
	if err == ErrDisabled {
		return nil
	}

	if err != nil {
		return err
	}

	event.Properties["groupName"] = ch.GroupName
	event.Properties["message"] = StartCollBody

	return c.exporter.Send(event)
}

// WorkspaceCreated sends an event to Iterable, when a new workspace
// is created. In 'create workspace' workflow, we are intercepting these events.
// Depending on this, when it is user's first workspace,
// Iterable is calling our webhook for creating bot messages
func (c *Controller) WorkspaceCreated(w *WorkspaceData) error {

	event, err := c.prepareEvent(createWSEvent, w.AccountId)
	if err == ErrDisabled {
		return nil
	}

	if err != nil {
		return err
	}

	event.Properties["groupName"] = w.GroupName
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

	if c.isDisabled {
		isSuperAdmin, err := c.IsSuperAdmin(user.Name)
		if err != nil {
			return nil, err
		}
		if !isSuperAdmin {
			return nil, ErrDisabled
		}
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

// TODO This is a temporary method used until we permanently enable bot channel
func (c *Controller) IsSuperAdmin(nick string) (bool, error) {
	data, err := c.accountCache.Get(nick)
	if err == nil {
		isSuperAdmin, ok := data.(bool)
		if ok {
			return isSuperAdmin, nil
		}
	}

	if err != cache.ErrNotFound {
		return false, err
	}

	account, err := modelhelper.GetAccount(nick)
	if err == mgo.ErrNotFound {
		return false, nil
	}

	if err != nil {
		return false, err
	}

	if err := c.accountCache.Set(nick, account.HasFlag("super-admin")); err != nil {
		return false, err
	}

	return account.HasFlag("super-admin"), nil
}
