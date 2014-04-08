package popular

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
	"strconv"
	"time"

	"github.com/koding/bongo"
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
	topics, err := redisConn.SortedSetReverseRange(key, query.Skip, query.Limit)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	popularTopics := make([]int64, 0)
	for _, topic := range topics {
		val, err := strconv.ParseInt(string(topic.([]uint8)), 10, 64)
		if err == nil {
			popularTopics = append(popularTopics, val)
		}
	}

	fmt.Println("<<<<<<<<<<<<<<<<<<<<<@@22>>>>>>>>>>>>>", query.Limit)
	popularTopics, err = extendPopularTopicsIfNeeded(query, popularTopics)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	c := models.NewChannel()
	return helpers.HandleResultAndError(c.FetchByIds(popularTopics))
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
	selector := map[string]interface{}{
		"group_name":    group,
		"type_constant": models.Channel_TYPE_TOPIC,
	}
	query := bongo.NewQS(selector)
	query.Limit = count
	c := models.NewChannel()
	var channels []models.Channel
	err := c.Some(&channels, query)
	if err != nil {
		return nil, err
	}

	return channels, nil

}
