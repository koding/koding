// Package collaboration provides the logical part for the long running
// operations of collaboration worker
package collaboration

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/klient"
	"net/http"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"socialapi/workers/collaboration/models"
	"strconv"
	"strings"
	"time"

	"code.google.com/p/goauth2/oauth"
	"code.google.com/p/goauth2/oauth/jwt"
	"code.google.com/p/google-api-go-client/drive/v2"
	"code.google.com/p/google-api-go-client/googleapi"
	"github.com/cenkalti/backoff"
	"github.com/koding/bongo"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"

	"labix.org/v2/mgo"
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

	var err Error

	for errC := range errChan {
		if errC != nil {
			err = append(err, errC)
		}
	}

	return err
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
				c.log.Error("err while connecting: %s  will retry...", err.Error())
				continue
			}

			break
		}

		if err != nil {
			errChan <- err
		}

		errChan <- nil
	}()
}

// EndPrivateMessage stops the collaboration session
func (c *Controller) EndPrivateMessage(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	id, err := strconv.ParseInt(ping.ChannelId, 10, 64)
	if err != nil {
		return nil
	}

	// fetch the channel
	channel := socialapimodels.NewChannel()
	if err := channel.ById(id); err != nil {
		// if channel is not there, do not do anyting
		if err == bongo.RecordNotFound {
			return nil
		}

		return err
	}

	// delete the channel
	return channel.Delete()
}

func (c *Controller) UnshareVM(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(ping.ChannelId)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the workspace is not there, nothing to do
	if err != mgo.ErrNotFound {
		return nil
	}

	return modelhelper.UnshareMachineByUid(ws.MachineUID)
}

func (c *Controller) RemoveUsersFromMachine(ping *models.Ping) error {
	// if channel id is nil, there is nothing to do
	if ping.ChannelId == "" {
		return nil
	}

	ws, err := modelhelper.GetWorkspaceByChannelId(ping.ChannelId)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the workspace is not there, nothing to do
	if err != mgo.ErrNotFound {
		return nil
	}

	m, err := modelhelper.GetMachineByUid(ws.MachineUID)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	// if the machine is not there, nothing to do
	if err != mgo.ErrNotFound {
		return nil
	}

	// Get the klient.
	klientRef, err := klient.ConnectTimeout(c.kite, m.QueryString, time.Second*10)
	if err != nil {
		if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
			c.log.Error(
				"[%s] Klient is not registered to Kontrol. Err: %s",
				m.QueryString,
				err,
			)

			return nil // if the machine is not open, we cant do anything
		}

		return err
	}

	type req struct {
		Username string

		// we are gonna use this propery here, just for reference
		Permanent bool
	}

	var iterErr error
	for _, user := range m.Users {
		// do not unshare from owner user
		if user.Sudo && user.Owner {
			continue
		}

		// fetch user for its username
		u, err := modelhelper.GetUserById(user.Id.Hex())
		if err != nil {
			c.log.Error(err.Error())
			// if we cant find the regarding user, do not do anything
			if err == mgo.ErrNotFound {
				continue
			}

			iterErr = err
			// do not stop iterating, unshare from others
			continue
		}

		param := req{
			Username: u.Name,
		}

		_, err = klientRef.Client().Tell("klient.unshare", param)
		if err != nil {
			// those are so error prone, force klient side not to change the API
			// or make them exported to some other package?
			if strings.Contains(err.Error(), "user is permanent") {
				continue
			}

			if strings.Contains(err.Error(), "user is not in the shared list") {
				continue
			}

			c.log.Error(err.Error())
			iterErr = err
			continue // do not stop iterating, unshare from others
		}
	}

	// iterErr will be nil if we dont encounter to any error in iter
	return iterErr

}

func (c *Controller) DeleteDriveDoc(ping *models.Ping) error {
	return c.deleteFile(ping.FileId)
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

// deleteFile deletes the file from google drive api, if file is not there
// doesnt do anything
func (c *Controller) deleteFile(fileId string) error {
	svc, err := c.createService()
	if err != nil {
		return err
	}

	// files delete call
	err = svc.Files.Delete(fileId).Do()
	if err != nil {
		if e, ok := err.(*googleapi.Error); ok {
			if e.Code == 404 { // file not found
				return nil
			}
		}
		return err
	}

	return nil
}

// getFile gets the file from google drive api
func (c *Controller) getFile(fileId string) (*drive.File, error) {
	svc, err := c.createService()
	if err != nil {
		return nil, err
	}

	//get the file
	return svc.Files.Get(fileId).Do()
}

// createService creates a service with Server auth enabled system
func (c *Controller) createService() (*drive.Service, error) {
	gs := c.conf.GoogleapiServiceAccount

	// Settings for authorization.
	var configG = &oauth.Config{
		ClientId:     gs.ClientId,
		ClientSecret: gs.ClientSecret,
		Scope:        "https://www.googleapis.com/auth/drive",
		RedirectURL:  "urn:ietf:wg:oauth:2.0:oob",
		AuthURL:      "https://accounts.google.com/o/oauth2/auth",
		TokenURL:     "https://accounts.google.com/o/oauth2/token",
	}

	// Read the pem file bytes for the private key.
	keyBytes, err := ioutil.ReadFile(gs.ServiceAccountKeyFile)
	if err != nil {
		return nil, err
	}

	// Craft the ClaimSet and JWT token.
	t := jwt.NewToken(gs.ServiceAccountEmail, configG.Scope, keyBytes)
	t.ClaimSet.Aud = configG.TokenURL

	// Get the access token.
	o, err := t.Assert(&http.Client{}) // We need to provide a client.
	if err != nil {
		return nil, err
	}

	tr := &oauth.Transport{
		Config:    configG,
		Token:     o,
		Transport: http.DefaultTransport,
	}

	// Create a new authorized Drive client.
	svc, err := drive.New(tr.Client())
	if err != nil {
		return nil, err
	}

	return svc, nil
}

// Error contains error responses.
type Error []error

// Error returns the err string
func (e Error) Error() string {
	if len(e) == 0 {
		return ""
	}

	return fmt.Sprintf("collaboration: %v", e)
}
