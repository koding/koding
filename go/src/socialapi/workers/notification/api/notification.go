package api

import (
	"errors"
	"github.com/jinzhu/gorm"
	// "github.com/koding/bongo"
	"github.com/koding/logging"
	"math"
	"net/http"
	"net/url"
	"socialapi/config"
	socialmodels "socialapi/models" // TODO this dependancy must be removed
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/helper"
	"socialapi/workers/notification/models"
	"strconv"
)

var (
	NOTIFICATION_LIMIT = 8
	ACTOR_LIMIT        = 3
	cacheEnabled       = false
	log                logging.Logger
)

const (
	NOTIFICATION_TYPE_SUBSCRIBE   = "subscribe"
	NOTIFICATION_TYPE_UNSUBSCRIBE = "unsubscribe"
)

func init() {
	log = helper.CreateLogger("NotificationAPI", false)
	helpers.Log = log
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)
	if err := validateNotificationRequest(q); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	conf := config.Get()
	cacheEnabled = conf.Cache.Notification

	urlQuery := u.Query()
	cache, err := strconv.ParseBool(urlQuery.Get("cache"))
	if err == nil {
		cacheEnabled = cache
	}

	list, err := fetchNotifications(q)
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(list)
}

func Glance(u *url.URL, h http.Header, req *models.Notification) (int, http.Header, interface{}, error) {
	q := socialmodels.NewQuery()
	q.AccountId = req.AccountId
	if err := validateNotificationRequest(q); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.Glance(); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}

		return helpers.NewBadRequestResponse(err)
	}

	// TODO enable cache
	// go func() {
	// 	if cacheEnabled {
	// 		cacheInstance := cache.NewNotificationCache()
	// 		cacheInstance.Glance(req)
	// 	}
	// }()

	req.Glanced = true

	return helpers.NewDefaultOKResponse()
}

func Follow(u *url.URL, h http.Header, req *models.NotificationRequest) (int, http.Header, interface{}, error) {
	c := socialmodels.NewChannel()
	c.TypeConstant = socialmodels.Channel_TYPE_FOLLOWERS
	c.CreatorId = req.TargetId
	if err := c.Create(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	_, err := c.AddParticipant(req.AccountId)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}

func SubscribeMessage(u *url.URL, h http.Header, req *models.NotificationRequest) (int, http.Header, interface{}, error) {
	if err := subscription(req, NOTIFICATION_TYPE_SUBSCRIBE); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}

func UnsubscribeMessage(u *url.URL, h http.Header, req *models.NotificationRequest) (int, http.Header, interface{}, error) {
	if err := subscription(req, NOTIFICATION_TYPE_UNSUBSCRIBE); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewDefaultOKResponse()
}

func subscription(nr *models.NotificationRequest, typeConstant string) error {
	if err := validateSubscriptionRequest(nr); err != nil {
		return err
	}

	nc := models.NewNotificationContent()
	nc.TargetId = nr.TargetId
	nc.TypeConstant = typeConstant

	n := models.NewNotification()
	n.AccountId = nr.AccountId
	var err error
	switch typeConstant {
	case NOTIFICATION_TYPE_SUBSCRIBE:
		err = n.Subscribe(nc)
	case NOTIFICATION_TYPE_UNSUBSCRIBE:
		err = n.Unsubscribe(nc)
	}
	if err != nil {
		return err
	}

	return nil
}

func fetchNotifications(q *socialmodels.Query) (*models.NotificationResponse, error) {
	var list *models.NotificationResponse
	var err error

	// TODO enable cache
	// first check redis
	// var cacheInstance *cache.NotificationCache
	// if cacheEnabled {
	// 	cacheInstance = cache.NewNotificationCache()
	// 	cacheInstance.ActorLimit = ACTOR_LIMIT
	// 	list, err = cacheInstance.FetchNotifications(q.AccountId)
	// 	if err != nil {
	// 		log.Error("Cache error: %s", err)
	// 	}
	// 	if err == nil && len(list.Notifications) > 0 {
	// 		return list, nil
	// 	}
	// }

	n := models.NewNotification()
	list, err = n.List(q)
	if err != nil {
		return nil, err
	}

	// TODO enable cache update
	// go func() {
	// 	if cacheEnabled {
	// 		if err := cacheInstance.UpdateCachedNotifications(q.AccountId, list); err != nil {
	// 			log.Error("Cache cannot be updated: %s", err)
	// 		}
	// 	}
	// }()

	return list, nil
}

func validateNotificationRequest(q *socialmodels.Query) error {
	if err := validateAccount(q.AccountId); err != nil {
		return err
	}
	// update the limit if it is needed
	q.Limit = int(math.Min(float64(q.Limit), float64(NOTIFICATION_LIMIT)))

	return nil
}

func validateSubscriptionRequest(req *models.NotificationRequest) error {
	if err := validateAccount(req.AccountId); err != nil {
		return err
	}

	cm := socialmodels.NewChannelMessage()
	if err := cm.ById(req.TargetId); err != nil {
		return err
	}

	return nil
}

func validateAccount(accountId int64) error {
	a := socialmodels.NewAccount()
	if accountId == 0 {
		return errors.New("Account id cannot be empty")
	}

	if err := a.ById(accountId); err != nil {
		if err == gorm.RecordNotFound {
			return errors.New("Account is not valid")
		}
		return err
	}

	return nil
}

func validateMessage(messageId int64) error {
	cm := socialmodels.NewChannelMessage()
	if err := cm.ById(messageId); err != nil {
		if err == gorm.RecordNotFound {
			return errors.New("Channel message does not exist")
		}
		return err
	}

	return nil
}
