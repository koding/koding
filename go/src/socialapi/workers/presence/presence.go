// Package presence provides the logical part for the long running
// operations of presence worker
package presence

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/cache"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	// EventName holds presence event name
	EventName = "presence_ping"
)

var (
	pingCache = cache.NewMemoryWithTTL(time.Hour)
	// send pings every 30 secs
	pingDuration = time.Second * 30
)

// Controller holds the basic context data for handlers
type Controller struct {
	log  logging.Logger
	conf *config.Config
}

// New creates a controller
func New(log logging.Logger, conf *config.Config) *Controller {
	return &Controller{
		log:  log,
		conf: conf,
	}
}

// DefaultErrHandler handles the errors for presence worker
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	delivery.Nack(false, true)
	return false
}

func validate(ping *Ping) error {
	if ping.GroupName == "" {
		return fmt.Errorf("fileId is missing %+v", ping)
	}

	if ping.AccountID == 0 {
		return fmt.Errorf("accountId is missing %+v", ping)
	}

	return nil
}

// Ping handles the pings coming from client side
func (c *Controller) Ping(ping *Ping) error {
	c.log.Debug("new ping %+v", ping)
	if err := validate(ping); err != nil {
		c.log.Error("validation error:%s", err.Error())
		return nil
	}

	today := getTodayBeginningDate()
	// we add date here to invalidate cache item(s) after date changes
	key := getKey(ping, today)

	// if we find item in the cache, that means we processed it previously
	if _, err := pingCache.Get(key); err == nil {
		return nil
	}

	if err := verifyRecord(ping, today); err != nil {
		return err
	}

	return pingCache.Set(key, struct{}{})
}

func getKey(ping *Ping, today time.Time) string {
	return fmt.Sprintf("%s_%d_%d", ping.GroupName, ping.AccountID, today.Day())
}

// verifyRecord checks if the daily occurence is in the db, if not found creates
// a new record, if found and it is greater than today's beginning time returns
// nil. If it is smaller than today, creates a new record in the db
func verifyRecord(ping *Ping, today time.Time) error {
	p, err := getPresenceInfoFromDB(ping)
	if err != nil && err != bongo.RecordNotFound {
		return err // if we have non app specific err, return it
	}

	// if our record is persisted today, skip updating. We will update the record
	// once a day
	if p != nil && p.CreatedAt.Unix() > today.Unix() {
		return nil
	}

	return insertPresenceInfoToDB(ping)
}

func getTodayBeginningDate() time.Time {
	year, month, day := time.Now().UTC().Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
}

func getPresenceInfoFromDB(ping *Ping) (*models.PresenceDaily, error) {
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":   ping.GroupName,
			"account_id":   ping.AccountID,
			"is_processed": false,
		},
		Sort: map[string]string{
			"created_at": "DESC",
		},
	}
	a := &models.PresenceDaily{}
	if err := a.One(q); err != nil {
		return nil, err
	}

	return a, nil
}

func insertPresenceInfoToDB(ping *Ping) error {
	p := &models.PresenceDaily{
		GroupName: ping.GroupName,
		AccountId: ping.AccountID,
		CreatedAt: ping.CreatedAt,
	}
	return p.Create()
}
