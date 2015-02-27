// Package collaboration provides the logical part for the long running
// operations of collaboration worker
package collaboration

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/workers/collaboration/models"
	"strconv"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

const (
	// FireEventName is a unique event name for the collaboration ping messages
	FireEventName = "fire"

	// KeyPrefix for redis
	KeyPrefix = "collaboration"
)

var (
	// durations
	//
	// send pings every 15minutes
	pingDuration = time.Second * 15

	// offset should be smaller than a ping
	offsetDuration = time.Second * 10

	// session should be terminated after this duration
	terminateSessionDuration = pingDuration * 4

	// ExpireSessionKeyDuration redis key expiration duration
	ExpireSessionKeyDuration = pingDuration * 5

	// how long the go routine will sleep
	sleepTime = terminateSessionDuration + offsetDuration

	// every go routine should be completed in this duration
	deadLineDuration = time.Minute * 3

	// errors
	//
	errSessionInvalid  = errors.New("session is invalid")
	errDeadlineReached = errors.New("couldnt process the message in deadline")
)

// Controller holds the basic context data for handlers
type Controller struct {
	log   logging.Logger
	redis *redis.RedisSession
	conf  *config.Config
	kite  *kite.Kite
}

// New creates a controller
func New(
	log logging.Logger,
	redis *redis.RedisSession,
	conf *config.Config,
	kite *kite.Kite,
) *Controller {
	return &Controller{
		log:   log,
		redis: redis,
		conf:  conf,
		kite:  kite,
	}
}

// DefaultErrHandler handles the errors for collaboration worker
func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	delivery.Nack(false, true)
	return false
}

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

	err = c.wait(ping) // wait syncronously
	if err != nil && err != errSessionInvalid {
		return err
	}

	if err == errSessionInvalid {
		// key should be there
		// end the collab session
		c.log.Info("session is not valid anymore, collab should be terminated")
		return nil
	}

	return nil
}

func (c *Controller) wait(ping *models.Ping) error {
	select {
	// wait for terminate
	// (session terminate duration + and some offset)
	case <-time.After(sleepTime):
		// check if another ping is set
		// if the key is deleted, it means someone already deleted it
		return c.checkIfKeyIsValid(ping)
	case <-time.After(deadLineDuration):
		return errDeadlineReached
	}
}

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
		// discard this case, if the time is invalid, we should not try
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

func (c *Controller) EndSession(ping *models.Ping) error {
	errChan := make(chan error, 3)
	c.goWithRetry(func() error {
		return c.EndPrivateMessage(ping)
	}, errChan)

	c.goWithRetry(func() error {
		// first remove the users from klient
		if err := c.RemoveUsersFromMachine(ping); err != nil {
			return err
		}

		// then remove them from the db
		return c.UnshareVM(ping)
	}, errChan)

	c.goWithRetry(func() error {
		return c.DeleteDriveDoc(ping)
	}, errChan)

	var multiErr Error

	for err := range errChan {
		if err != nil {
			multiErr = append(multiErr, err)
		}
	}

	return multiErr
}

func (c *Controller) goWithRetry(f func() error, errChan chan error) {
	go func() {
		bo := backoff.NewExponentialBackOff()
		bo.InitialInterval = time.Millisecond * 250
		bo.MaxInterval = time.Second * 1
		bo.MaxElapsedTime = time.Minute * 2 // channel message can take some time

		ticker := backoff.NewTicker(bo)
		defer ticker.Stop()

		var err error
		for _ = range ticker.C {
			if err = f(); err != nil {
				c.log.Error("err while operating: %s  will retry...", err.Error())
				continue
			}

			break
		}

		errChan <- err
	}()
}

// PrepareFileKey prepares a key for redis
func PrepareFileKey(fileId string) string {
	return fmt.Sprintf(
		"%s:%s:%s",
		config.MustGet().Environment,
		KeyPrefix,
		fileId,
	)
}

// Error contains error responses.
type Error []error

// Error returns the err string
func (e Error) Error() string {
	if len(e) == 0 {
		return ""
	}

	return fmt.Sprintf("collaboration: %+v", e)
}
