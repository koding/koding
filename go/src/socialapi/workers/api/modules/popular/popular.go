package popular

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
	"strconv"
	"time"
)

func getDateNumberAndYear(statisticName string) (int, int, error) {
	now := time.Now().UTC()
	// dateNumber is changing according to the statisticName
	// if it is monthly statistic, it will be month number March->3
	// if it is weekly statistic, it will be week number 48th week -> 48
	// if it is daily statistic, it will the day number of the year e.g last day-> 365+1
	switch statisticName {
	case "daily":
		return now.Year(), now.YearDay(), nil
	case "weekly":
		year, week := now.ISOWeek()
		return year, week, nil
	case "monthly":
		return now.Year(), int(now.Month()), nil
	default:
		return 0, 0, errors.New("Unknown statistic name")
	}
}

func getIds(key string, query *models.Query) ([]int64, error) {
	// limit-1 is important, because redis is using 0 based index
	popularIds := make([]int64, 0)
	listIds, err := helper.MustGetRedisConn().
		SortedSetReverseRange(
		key,
		query.Skip,
		query.Skip+query.Limit-1,
	)

	if err != nil {
		return popularIds, err
	}

	for _, listId := range listIds {
		val, err := strconv.ParseInt(string(listId.([]uint8)), 10, 64)
		if err == nil {
			popularIds = append(popularIds, val)
		}
	}

	return popularIds, nil
}

func ListTopics(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := helpers.GetQuery(u)

	statisticName := u.Query().Get("statisticName")

	year, dateNumber, err := getDateNumberAndYear(statisticName)
	if err != nil {
		return helpers.NewBadRequestResponse(errors.New("Unknown statistic name"))
	}

	key := populartopic.PreparePopularTopicKey(
		query.GroupName,
		statisticName,
		year,
		dateNumber,
	)

	popularTopicIds, err := getIds(key, query)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
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

	return helpers.HandleResultAndError(
		models.PopulateChannelContainers(
			popularTopics,
			query.AccountId,
		),
	)
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
