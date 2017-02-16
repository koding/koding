// Package collaboration provides the logical part for the long running
// operations of collaboration worker
package collaboration

import (
	"bytes"
	"errors"
	"fmt"
	"socialapi/config"
	socialapimodels "socialapi/models"

	"github.com/koding/bongo"
	"github.com/koding/cache"

	"socialapi/workers/collaboration/models"
	"sync"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/koding/kite"
	"github.com/koding/logging"
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
	log        logging.Logger
	mongoCache *cache.MongoCache
	conf       *config.Config
	kite       *kite.Kite
}

// New creates a controller
func New(
	log logging.Logger,
	mongoCache *cache.MongoCache,
	conf *config.Config,
	kite *kite.Kite,
) *Controller {
	return &Controller{
		log:        log,
		mongoCache: mongoCache,
		conf:       conf,
		kite:       kite,
	}
}

// DefaultErrHandler handles the errors for collaboration worker
func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	delivery.Nack(false, true)
	return false
}

func validate(ping *models.Ping) error {
	if ping.FileId == "" {
		return fmt.Errorf("fileId is missing %+v", ping)
	}

	if ping.AccountId == 0 {
		return fmt.Errorf("accountId is missing %+v", ping)
	}

	if ping.ChannelId == 0 {
		return fmt.Errorf("channelId is missing %+v", ping)
	}

	return nil
}

// Ping handles the pings coming from client side
func (c *Controller) Ping(ping *models.Ping) error {
	c.log.Debug("new ping %+v", ping)
	if err := validate(ping); err != nil {
		c.log.Error("validation error:%s", err.Error())
		return nil
	}

	err := CanOpen(ping)
	if err != nil && err != socialapimodels.ErrCannotOpenChannel {
		return err
	}

	if err == socialapimodels.ErrCannotOpenChannel {
		return nil
	}

	err = c.checkIfKeyIsValid(ping)
	if err != nil && err != errSessionInvalid {
		c.log.Error("key is not valid %+v", err.Error())
		return err
	}

	if err == errSessionInvalid {
		c.log.Info("session is not valid anymore, collab should be terminated %+v", ping)
		return c.EndSession(ping)
	}

	err = c.wait(ping) // wait synchronously
	if err != nil && err != errSessionInvalid {
		c.log.Error("err while waiting %+v", err)
		return err
	}

	if err == errSessionInvalid {
		c.log.Info("session is not valid anymore, collab should be terminated %+v", ping)
		return c.EndSession(ping)
	}

	c.log.Debug("session is valid %+v", ping)

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

func (c *Controller) checkIfKeyIsValid(ping *models.Ping) (err error) {
	defer func() {
		if err != nil {
			c.log.Debug("ping: %+v is not valid err: %+v", ping, err)
		}
	}()

	// check the redis key if it doesnt exist
	key := PrepareFileKey(ping.FileId)
	pingTime, err := c.mongoCache.Get(key)
	if err != nil && err != cache.ErrNotFound {
		return err
	}
	if err == cache.ErrNotFound {
		c.log.Debug("key is not found %+v", ping)
		return errSessionInvalid // key is not there
	}

	unixSec, ok := pingTime.(int64)
	if !ok {
		return errSessionInvalid
	}

	lastPingTime := time.Unix(unixSec, 0).UTC()

	now := time.Now().UTC()

	if now.Add(-terminateSessionDuration).After(lastPingTime) {
		return errSessionInvalid
	}

	// session is valid
	return nil
}

func (c *Controller) EndSession(ping *models.Ping) error {
	var multiErr Error

	defer func() {
		if multiErr != nil {
			c.log.Debug("ping: %+v is not valid %+v err: %+v", ping, multiErr)
		}
	}()

	errChan := make(chan error)
	var wg sync.WaitGroup

	c.goWithRetry(func() error {
		// IMPORTANT
		// 	- DO NOT CHANGE THE ORDER
		//
		toBeRemovedUsers, err := c.findToBeRemovedUsers(ping)
		if err != nil {
			return err
		}

		// then remove them from the db
		if err := c.UnshareVM(ping, toBeRemovedUsers); err != nil {
			return err
		}

		// first remove the users from klient
		if err := c.RemoveUsersFromMachine(ping, toBeRemovedUsers); err != nil {
			return err
		}

		// then end the private messaging
		return c.EndPrivateMessage(ping)
	}, errChan, &wg)

	c.goWithRetry(func() error {
		return c.DeleteDriveDoc(ping)
	}, errChan, &wg)

	go func() {
		// wait until all of them are finised
		wg.Wait()

		// we are done with the operations
		close(errChan)
	}()

	for err := range errChan {
		if err != nil {
			multiErr = append(multiErr, err)
		}
	}

	if len(multiErr) == 0 {
		return nil
	}

	return multiErr
}

func (c *Controller) goWithRetry(f func() error, errChan chan error, wg *sync.WaitGroup) {
	wg.Add(1)
	go func() {
		defer wg.Done()
		bo := backoff.NewExponentialBackOff()
		bo.InitialInterval = time.Millisecond * 250
		bo.MaxInterval = time.Second * 1
		bo.MaxElapsedTime = time.Minute * 2 // channel message can take some time

		ticker := backoff.NewTicker(bo)
		defer ticker.Stop()

		var err error
		for range ticker.C {
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

func CanOpen(ping *models.Ping) error {
	// fetch the channel
	channel := socialapimodels.NewChannel()
	if err := channel.ById(ping.ChannelId); err != nil {
		// if channel is not there, do not do anyting
		if err == bongo.RecordNotFound {
			return nil
		}

		return err
	}

	canOpen, err := channel.CanOpen(ping.AccountId)
	if err != nil {
		return err
	}

	if !canOpen {
		// if the requester can not open the channel do not process
		return socialapimodels.ErrCannotOpenChannel
	}

	return nil
}

// Error contains error responses.
type Error []error

// Error returns the err string
func (e Error) Error() string {
	var buf bytes.Buffer

	if len(e) == 1 {
		buf.WriteString("1 error: ")
	} else {
		fmt.Fprintf(&buf, "%d errors: ", len(e))
	}

	for i, err := range e {
		if i != 0 {
			buf.WriteString("; ")
		}

		buf.WriteString(err.Error())
	}

	return buf.String()
}
