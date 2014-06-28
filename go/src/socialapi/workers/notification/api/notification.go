package api

import (
	"errors"
	"math"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/request"
	// TODO delete these socialapi dependencies
	socialmodels "socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/notification/models"
	"strconv"

	"github.com/koding/bongo"
	// "github.com/koding/bongo"
)

var (
	NOTIFICATION_LIMIT = 8
	ACTOR_LIMIT        = 3
	cacheEnabled       = false
)

const (
	NOTIFICATION_TYPE_SUBSCRIBE   = "subscribe"
	NOTIFICATION_TYPE_UNSUBSCRIBE = "unsubscribe"
)

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)
	if err := validateNotificationRequest(q); err != nil {
		return response.NewBadRequest(err)
	}

	conf := config.MustGet()
	cacheEnabled = conf.Notification.CacheEnabled

	urlQuery := u.Query()
	cache, err := strconv.ParseBool(urlQuery.Get("cache"))
	if err == nil {
		cacheEnabled = cache
	}

	return response.HandleResultAndError(fetchNotifications(q))
}

func Glance(u *url.URL, h http.Header, req *models.Notification) (int, http.Header, interface{}, error) {
	q := request.NewQuery()
	q.AccountId = req.AccountId
	if err := validateNotificationRequest(q); err != nil {
		return response.NewBadRequest(err)
	}
	if err := req.Glance(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}

func fetchNotifications(q *request.Query) (*models.NotificationResponse, error) {
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

func validateNotificationRequest(q *request.Query) error {
	if err := validateAccount(q.AccountId); err != nil {
		return err
	}
	// update the limit if it is needed
	q.Limit = int(math.Min(float64(q.Limit), float64(NOTIFICATION_LIMIT)))

	return nil
}

func validateAccount(accountId int64) error {
	a := socialmodels.NewAccount()
	if accountId == 0 {
		return errors.New("Account id cannot be empty")
	}

	if err := a.ById(accountId); err != nil {
		if err == bongo.RecordNotFound {
			return errors.New("Account is not valid")
		}
		return err
	}

	return nil
}

func validateMessage(messageId int64) error {
	if err := socialmodels.NewChannelMessage().ById(messageId); err != nil {
		if err == bongo.RecordNotFound {
			return errors.New("Channel message does not exist")
		}
		return err
	}

	return nil
}
