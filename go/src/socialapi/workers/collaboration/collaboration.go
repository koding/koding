// collaboration package provides the logical part for the long running
// operations of collaboration worker
package collaboration

import (
	"errors"
	"fmt"
	"socialapi/workers/collaboration/models"
	"strconv"
	"time"

	"socialapi/config"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

const (
	// FireEventName is a unique event name for the collaboration ping messages
	FireEventName = "fire"
)

// Controller holds the basic context data for handlers
type Controller struct {
	log   logging.Logger
	redis *redis.RedisSession
}

// DefaultErrHandler handles the errors for collaboration worker
func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	delivery.Nack(false, true)
	return false
}

// New creates a controller
func New(log logging.Logger, redis *redis.RedisSession) *Controller {
	return &Controller{
		log:   log,
		redis: redis,
	}
}

// send pings every 15minutes
var pingDuration = time.Second * 15

// offset should be smaller than a ping
var offsetDuration = time.Second * 10

// session should be terminated after this duration
var terminateSessionDuration = pingDuration * 4

// ExpireSessionKeyDuration redis key expiration duration
var ExpireSessionKeyDuration = pingDuration * 5

// how long the go routine will sleep
var sleepTime = terminateSessionDuration + offsetDuration

// every go routine should be completed in this duration
var deadLineDuration = sleepTime + time.Second*5

// Ping handles the pings coming from client side
func (c *Controller) Ping(ping *models.Ping) error {
	c.log.Debug("new ping %+v", ping)

	if ping.FileId == "" {
		c.log.Error("fileId is missing %+v", ping)
		return nil
	}

	if ping.AccountId == 0 {
		c.log.Error("accountId is missing %+v", ping)
		return nil
	}

	err := c.checkIfKeyIsValid(ping)
	if err != nil && err != errSessionInvalid {
		return err
	}

	if err == errSessionInvalid {
		// key should be there
		// end the collab session
		c.log.Info("session is not valid anymore, collab should be terminated")
		return nil
	}

	select {
	// wait for terminate
	// (session terminate duration + and some offset)
	case <-time.After(sleepTime):
		// check if another ping is set
		// if the key is deleted, it means someone already deleted it
		err := c.checkIfKeyIsValid(ping)
		if err != nil && err != errSessionInvalid {
			return err
		}

		if err == errSessionInvalid {
			// key should be there
			// end the collab session
			c.log.Info("session is not valid anymore, collab should be terminated")
			return nil
		}

		// session is still valid
		return nil

		// if we cant finish our process in deadline period, re-add the message
		// to the RMQ
	case <-time.After(deadLineDuration):
		return errors.New("couldnt process the message")
	}
}

var errSessionInvalid = errors.New("session is invalid")

func (c *Controller) checkIfKeyIsValid(ping *models.Ping) error {
	var err error
	defer func() {
		if err != nil {
			c.log.Debug("ping: %+v is not valid %+v err: %+v", ping, err)
		}
	}()

	// check the redis key if it doesnt exist
	key := PrepareFileKey(ping.FileId)
	file, err := c.redis.Get(key)
	if err != nil && err != redis.ErrNil {
		return err
	}

	if err == redis.ErrNil {
		return errSessionInvalid // key is not there
	}

	unixSec, err := strconv.ParseInt(file, 10, 64)
	if err != nil {
		c.log.Error(err.Error())
		// silently discard this case, if the time is invalid, we should not try
		// to process it again
		return errSessionInvalid // key is not valid
	}

	t := time.Unix(unixSec, 0)

	newPingTime := ping.CreatedAt
	// if sum of previous ping time and terminate session duration is before the
	// current ping time, terminate the session
	if t.Add(terminateSessionDuration).Before(newPingTime) {
		return errSessionInvalid
	}

	// session is valid
	return nil
}

const CACHEPREFIX = "collaboration"

func PrepareFileKey(fileId string) string {
	return fmt.Sprintf(
		"%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		fileId,
	)
}
