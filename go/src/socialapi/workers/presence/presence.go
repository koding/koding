// Package presence provides the logical part for the long running
// operations of presence worker
package presence

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"time"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	// EndpointPresencePing provides ping endpoint
	EndpointPresencePing = "/presence/ping"

	// EndpointPresenceListMembers lists the members that were active
	EndpointPresenceListMembers = "/presence/listmembers"

	// EndpointPresencePingPrivate provides private ping endpoint
	EndpointPresencePingPrivate = "/private/presence/ping"
)

const (
	// EventName holds presence event name
	EventName = "presence_ping"
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

	status, err := getGroupPaymentStatus(ping.GroupName)
	if err == mgo.ErrNotFound {
		return nil // if group is not found in db, no need to process further
	}

	if err != nil {
		return err
	}

	ping.paymentStatus = status

	today := getTodayBeginningDate()
	return verifyRecord(ping, today)
}

// verifyRecord checks if the daily occurrence is in the db, if not found creates
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
			"group_name": ping.GroupName,
			"account_id": ping.AccountID,
			// if payment status is active, we should get the last unprocessed, but if
			// it is not active, we are persisting pings as processed, so fetch latest
			// processed in that case
			//
			// One big question is why we store non active sub-ed team's ping requests
			// as processed? We wont be charging trailing teams before second month's
			// payment is due, so we start collecting presence info( with processed
			// false )  after the first month, and first month is completely free.
			// Second issue is, when a sub is in non-active state, we should still
			// collect presence info but we wont be charging users during that period,
			// because we dont allow them to utilize koding
			"is_processed": ping.paymentStatus != string(mongomodels.SubStatusActive),
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
		GroupName:   ping.GroupName,
		AccountId:   ping.AccountID,
		CreatedAt:   ping.CreatedAt,
		IsProcessed: ping.paymentStatus != string(mongomodels.SubStatusActive),
	}
	return p.Create()
}

func getGroupPaymentStatus(groupName string) (string, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return "", err
	}

	status := group.Payment.Subscription.Status
	// set defaul payment status
	if status != mongomodels.SubStatusActive {
		status = "invalid"
	}

	return string(status), nil
}
