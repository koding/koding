package popular

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
	"strconv"
	"time"
)

func ListTopics(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := helpers.GetQuery(u)

	statisticName := u.Query().Get("statisticName")

	now := time.Now().UTC()
	// dateNumber is changing according to the statisticName
	// if it is monthly statistic, it will be month number March->3
	// if it is weekly statistic, it will be week number 48th week -> 48
	var dateNumber int
	year, month, _ := now.Date()

	if statisticName == "monthly" {
		dateNumber = int(month)
	} else {
		statisticName = "weekly"
		_, dateNumber = now.ISOWeek()
	}

	key := populartopic.PreparePopularTopicKey(
		query.GroupName,
		statisticName,
		year,
		dateNumber,
	)

	redisConn := helper.MustGetRedisConn()
	// limit-1 is important, because redis is using 0 based index
	topics, err := redisConn.SortedSetReverseRange(key, query.Skip, query.Skip+query.Limit-1)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	popularTopicIds := make([]int64, 0)
	for _, topic := range topics {
		val, err := strconv.ParseInt(string(topic.([]uint8)), 10, 64)
		if err == nil {
			popularTopicIds = append(popularTopicIds, val)
		}
	}

	popularTopicIds, err = extendPopularTopicsIfNeeded(query, popularTopicIds)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	c := models.NewChannel()
	popularTopics, err := c.FetchByIds(popularTopicIds)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	res := models.PopulateChannelContainers(popularTopics, query.AccountId)
	return helpers.NewOKResponse(res)
}

func extendPopularTopicsIfNeeded(query *models.Query, popularTopics []int64) ([]int64, error) {
	toBeAddedItemCount := query.Limit - len(popularTopics)

	if toBeAddedItemCount > 0 {
		normalChannels, err := fetchMoreChannels(query.GroupName, query.Limit)
		if err != nil {
			return popularTopics, err
		}

		for _, normalChannel := range normalChannels {
			exists := false
			for _, popularTopicId := range popularTopics {
				if normalChannel.Id == popularTopicId {
					exists = true
					break
				}
			}

			if !exists {
				popularTopics = append(popularTopics, normalChannel.Id)
				toBeAddedItemCount--
				if toBeAddedItemCount == 0 {
					break
				}
			}
		}
	}

	return popularTopics, nil
}

func fetchMoreChannels(group string, count int) ([]models.Channel, error) {
	q := models.NewQuery()
	q.GroupName = group
	q.Limit = count
	q.Type = models.Channel_TYPE_TOPIC
	q.SetDefaults()
	c := models.NewChannel()
	return c.List(q)
}
