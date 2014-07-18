package popular

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
	"socialapi/workers/popularpost/popularpost"
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

func getIds(key string, query *request.Query) ([]int64, error) {
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
	query := request.GetQuery(u)

	statisticName := u.Query().Get("statisticName")

	year, dateNumber, err := getDateNumberAndYear(statisticName)
	if err != nil {
		return response.NewBadRequest(errors.New("unknown statistic name"))
	}

	key := populartopic.PreparePopularTopicKey(
		query.GroupName,
		statisticName,
		year,
		dateNumber,
	)

	popularTopicIds, err := getIds(key, query)
	if err != nil {
		return response.NewBadRequest(err)
	}

	popularTopicIds, err = extendPopularTopicsIfNeeded(query, popularTopicIds)
	if err != nil {
		return response.NewBadRequest(err)
	}

	c := models.NewChannel()
	popularTopics, err := c.FetchByIds(popularTopicIds)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		models.PopulateChannelContainers(
			popularTopics,
			query.AccountId,
		),
	)
}

func extendPopularTopicsIfNeeded(query *request.Query, popularTopics []int64) ([]int64, error) {
	toBeAddedItemCount := query.Limit - len(popularTopics)

	if toBeAddedItemCount > 0 {
		normalChannels, err := fetchMoreChannels(query)
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

func fetchMoreChannels(query *request.Query) ([]models.Channel, error) {
	q := query.Clone()
	q.Type = models.Channel_TYPE_TOPIC

	return models.NewChannel().List(q)
}

func ListPosts(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	query := request.GetQuery(u)
	query.Type = models.ChannelMessage_TYPE_POST

	statisticName := u.Query().Get("statisticName")
	channelName := u.Query().Get("channelName")

	year, dateNumber, err := getDateNumberAndYear(statisticName)
	if err != nil {
		return response.NewBadRequest(errors.New("Unknown statistic name"))
	}

	key := popularpost.PreparePopularPostKey(
		query.GroupName,
		channelName,
		statisticName,
		year,
		dateNumber,
	)

	popularPostIds, err := getIds(key, query)
	if err != nil {
		return response.NewBadRequest(err)
	}

	popularPostIds, err = extendPopularPostsIfNeeded(query, popularPostIds, channelName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	popularPosts, err := models.NewChannelMessage().FetchByIds(popularPostIds)
	if err != nil {
		return response.NewBadRequest(err)
	}

	query.Limit = 3
	return response.HandleResultAndError(
		models.NewChannelMessage().BuildMessages(
			query,
			popularPosts,
		),
	)
}

func extendPopularPostsIfNeeded(query *request.Query, popularPostIds []int64, channelName string) ([]int64, error) {
	toBeAddedItemCount := query.Limit - len(popularPostIds)
	if toBeAddedItemCount > 0 {
		c := models.NewChannel()
		channelId, err := c.FetchChannelIdByNameAndGroupName(channelName, query.GroupName)
		if err != nil {
			return popularPostIds, err
		}

		normalPosts, err := models.NewChannelMessageList().FetchMessageIdsByChannelId(channelId, query)
		if err != nil {
			return popularPostIds, err
		}

		for _, normalPostId := range normalPosts {
			exists := false
			for _, popularPostId := range popularPostIds {
				if normalPostId == popularPostId {
					exists = true
					break
				}
			}

			if !exists {
				popularPostIds = append(popularPostIds, normalPostId)
				toBeAddedItemCount--
				if toBeAddedItemCount == 0 {
					break
				}
			}
		}
	}

	return popularPostIds, nil
}
