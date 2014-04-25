// This file is used for caching notifications
// When a user lists its notifications json result set is this
// notificationList: [
// {
// 	 typeConstant: "leave",
// 	 targetId: 24,
//   glanced: false,
//   latestActors: [ 150, 99, 48 ],
//   updatedAt: "2014-04-25T01:23:36.330053-07:00",
//   actorCount: 8
// }
// ],
// unreadCount: 3
//
// abbreviations:
// notificationKey : {typeConstant}-{targetId}
// accountKey      : account-{accountId}
//
// Each user's last 8 notificationKeys are stored in a set stored at key [accountKey]:list
// updatedAt values are used for sorting notifications and stored at key [accountKey]:updatedAt
// latestActors, glanced and actorCount values are stored in hashset with key [accountKey]:notificationKey
// unreadCount is stored with key [accountKey]:unreadCount

package notification

import (
	"fmt"
	"github.com/koding/redis"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/helper"
	"strconv"
	"strings"
	"time"
)

var (
	NotificationKey          = "notification"
	NotificationListKey      = "list"
	NotificationAccountKey   = "account"
	NotificationActorKey     = "actor"
	NotificationUnreadKey    = "unreadCount"
	NotificationUpdatedAtKey = "updatedAt"
	redisConn                *redis.RedisSession
)

// fetchCachedNotification fetches the notification list of the user if it already exists
func fetchCachedNotifications(accountId int64) (*models.NotificationResponse, error) {
	redisConn = helper.MustGetRedisConn()
	listContainerKey := getAccountCacheKeyWithSuffix(accountId, NotificationListKey)
	suffix := ":*:" + NotificationUpdatedAtKey
	sortKey := appendCachePrefix(suffix)
	members, err := redisConn.SortBy(listContainerKey, sortKey, "desc")
	if err != nil {
		return nil, err
	}

	if len(members) == 0 {
		return &models.NotificationResponse{}, nil
	}

	nr := &models.NotificationResponse{}

	ncList := make([]models.NotificationContainer, len(members))
	for i, member := range members {
		nc := &ncList[i]
		if err := populateNotificationFromCache(member, nc); err != nil {
			return nil, err
		}
	}
	nr.Notifications = ncList
	unreadKey := getAccountCacheKeyWithSuffix(accountId, NotificationUnreadKey)
	unreadCount, err := redisConn.GetInt(unreadKey)
	if err != nil {
		return nil, err
	}
	nr.UnreadCount = unreadCount

	return nr, nil
}

func populateNotificationFromCache(member interface{}, nc *models.NotificationContainer) error {
	redisConn = helper.MustGetRedisConn()
	memberValue, err := redisConn.String(member)
	itemKey := appendCachePrefix(memberValue)

	typeIdPair := strings.Split(itemKey, ":")[3]
	keys := strings.Split(typeIdPair, "-")

	nc.UpdatedAt, err = getUpdatedAt(itemKey)
	if err != nil {
		return err
	}

	nc.TypeConstant = keys[0]
	nc.TargetId, err = strconv.ParseInt(keys[1], 10, 64)
	fields := getCacheFields()
	values, err := redisConn.GetHashMultipleSet(itemKey, fields...)
	if err != nil {
		return err
	}

	nc.Glanced, err = redisConn.Bool(values[0])
	if err != nil {
		return err
	}

	nc.ActorCount, err = redisConn.Int(values[1])
	if err != nil {
		return err
	}

	for i := 2; i < len(values); i++ {
		actor, err := redisConn.Int64(values[i])
		if err == nil {
			nc.LatestActors = append(nc.LatestActors, actor)
		}
	}

	return nil
}

func getUpdatedAt(key string) (time.Time, error) {
	updatedAtKey := fmt.Sprintf("%s:%s", key, NotificationUpdatedAtKey)

	updatedAtValue, err := redisConn.GetInt(updatedAtKey)
	if err != nil {
		return time.Now(), err
	}

	return time.Unix(0, int64(updatedAtValue)), nil
}

// appendCachePrefix appends {environment}:notification prefix to the given suffix
func appendCachePrefix(suffix string) string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		NotificationKey,
		suffix,
	)
}

// getAccountCacheKey returns account key with prefix
// result: {environment}:notification:account-{id}
func getAccountCacheKey(accountId int64) string {
	suffix := fmt.Sprintf("%s-%d", NotificationAccountKey, accountId)
	return appendCachePrefix(suffix)
}

// getNotificationCacheKey returns notification key with prefix
// result: {environment}:notification:account-{id}:{typeConstant}-{targetId}
func getNotificationCacheKey(accountId, targetId int64, typeConstant string) string {
	prefix := getAccountCacheKey(accountId)
	return fmt.Sprintf(
		"%s:%s-%d",
		prefix,
		typeConstant,
		targetId,
	)
}

// getAccountKeyWithSuffix returns notification key with appended suffix
// result: {environment}:notification:account-{id}:{typeConstant}-{targetId}:{suffix}
func getAccountCacheKeyWithSuffix(accountId int64, suffix string) string {
	prefix := getAccountCacheKey(accountId)
	return fmt.Sprintf(
		"%s:%s",
		prefix,
		suffix,
	)
}

// getNotificationListMemberKey returns notification keys without prefixes
// result: account-{id}:{typeConstant}-{targetId}
func getNotificationListMemberKey(accountId int64, targetId int64, typeConstant string) string {
	return fmt.Sprintf(
		"%s-%d:%s-%d",
		NotificationAccountKey,
		accountId,
		typeConstant,
		targetId,
	)
}

func updateCachedNotifications(accountId int64, nr *models.NotificationResponse) error {
	redisConn = helper.MustGetRedisConn()
	listKey := getAccountCacheKeyWithSuffix(accountId, NotificationListKey)
	_, err := redisConn.Del(listKey)
	if err != nil {
		return err
	}

	listItemIds := make([]interface{}, 0)
	for _, nc := range nr.Notifications {
		itemKey := getNotificationCacheKey(accountId, nc.TargetId, nc.TypeConstant)
		if err := updateCacheItemModifiedDate(&nc, itemKey); err != nil {
			return err
		}

		if err := updateCachedItem(&nc, itemKey); err != nil {
			return err
		}

		listItemKey := getNotificationListMemberKey(accountId, nc.TargetId, nc.TypeConstant)
		listItemIds = append(listItemIds, listItemKey)
	}

	// update object lister
	if _, err := redisConn.AddSetMembers(listKey, listItemIds...); err != nil {
		return err
	}

	// update unread count
	unreadKey := getAccountCacheKeyWithSuffix(accountId, NotificationUnreadKey)
	if err := redisConn.Set(unreadKey, strconv.Itoa(nr.UnreadCount)); err != nil {
		return err
	}

	return nil
}

func updateCacheItemModifiedDate(nc *models.NotificationContainer, prefix string) error {
	prefix = fmt.Sprintf("%s:%s", prefix, NotificationUpdatedAtKey)

	return redisConn.Set(prefix, strconv.FormatInt(nc.UpdatedAt.UnixNano(), 10))
}

func updateCachedItem(nc *models.NotificationContainer, prefix string) error {
	instance := map[string]interface{}{
		"glanced":    nc.Glanced,
		"actorCount": nc.ActorCount,
	}

	for index, val := range nc.LatestActors {
		key := fmt.Sprintf("%s-%d", NotificationActorKey, index)
		instance[key] = val
	}

	return redisConn.HashMultipleSet(prefix, instance)
}

func getCacheFields() []interface{} {
	fields := []interface{}{"glanced", "actorCount"}
	for i := 0; i < ACTOR_LIMIT; i++ {
		actorField := fmt.Sprintf("%s-%d", NotificationActorKey, i)
		fields = append(fields, actorField)
	}

	return fields
}

func resetCache(accountId int64) error {
	redisConn := helper.MustGetRedisConn()
	prefix := getAccountCacheKeyWithSuffix(accountId, "*")
	// TODO instead of using Keys use stored values in set :list
	// members, err := redisConn.GetSetMembers(key)
	keys, err := redisConn.Keys(prefix)

	if err != nil {
		return err
	}

	deletedKeys := make([]interface{}, 0)
	for _, key := range keys {
		deleteKey, err := redisConn.String(key)
		if err == nil {
			deletedKeys = append(deletedKeys, deleteKey)
		}
	}

	_, err = redisConn.Del(deletedKeys...)
	if err != nil {
		fmt.Println("cache cannot be reset") // todolog
	}

	return err
}
