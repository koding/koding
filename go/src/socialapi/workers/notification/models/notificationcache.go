// This file is used for caching notifications
// When a user lists its notifications json result set is this
// notificationList: [
// {
//   typeConstant: "leave",
//   targetId: 24,
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
// compoundKey     : [accountKey]:[notificationKey]
//
// Each user's last 8 notificationKeys are stored in a set stored at key [accountKey]:list
// updatedAt values are used for sorting notifications and stored at key [accountKey]:updatedAt
// latestActors, glanced and actorCount values are stored in hashset with key [accountKey]:notificationKey
// unreadCount is stored with key [accountKey]:unreadCount

package models

import (
	"fmt"
	"github.com/koding/redis"
	"socialapi/config"
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
)

type NotificationCache struct {
	ActorLimit        int
	NotificationLimit int
	redisConn         *redis.RedisSession
}

func NewNotificationCache() *NotificationCache {
	redisConn := helper.MustGetRedisConn()
	return &NotificationCache{
		redisConn:         redisConn,
		NotificationLimit: 8,
	}
}

// FetchNotifications fetches the notification list of the user if it already exists.
// when there is an error it resets the cache related with account for preventing further
// error situations
func (cache *NotificationCache) FetchNotifications(accountId int64) (*NotificationResponse, error) {
	compoundKeys, err := cache.fetchSortedCompoundKeys(accountId)
	if err != nil {
		cache.resetCache(accountId)
		return nil, err
	}

	nr := &NotificationResponse{}

	if len(compoundKeys) == 0 {
		return nr, nil
	}

	// fetch notification list for the user
	ncList := make([]NotificationContainer, len(compoundKeys))
	for i, compoundKey := range compoundKeys {
		nc := &ncList[i]
		if err := cache.populateNotificationContainer(compoundKey, nc); err != nil {
			cache.resetCache(accountId)
			return nil, err
		}
	}
	nr.Notifications = ncList
	// fetch unread count
	unreadKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationUnreadKey)
	unreadCount, err := cache.redisConn.GetInt(unreadKey)
	if err != nil {
		cache.resetCache(accountId)
		return nil, err
	}
	nr.UnreadCount = unreadCount

	return nr, nil
}

// UpdateCache updates user's cache related with the notification item. If user's
// notifications are not cached, we just skip it. When an error occurrs we reset
// user's cache for preventing further error situations
func (cache *NotificationCache) UpdateCache(n *Notification, nc *NotificationContent) error {
	// Check if users notification data is cached.
	// When user did not listed her notifications for a while, then
	// no need for further caching
	if !cache.isCached(n.AccountId) {
		// TODO log.Debug(cache not hit for accountId)
		return nil
	}

	cacheHit, err := cache.updateCompoundKeyList(n, nc)
	if err != nil {
		cache.resetCache(n.AccountId)
		return err
	}

	if err := cache.addNotificationDetails(n, nc); err != nil {
		cache.resetCache(n.AccountId)
		return err
	}

	if err := cache.updateUnreadCount(n.AccountId); err != nil {
		cache.resetCache(n.AccountId)
		return err
	}

	// fetch oldest one and remove if needed and limit is reached
	if cacheHit {
		if err := cache.removeOldestItem(n, nc); err != nil {
			cache.resetCache(n.AccountId)
			return err
		}
	}

	return nil
}

// Glance iterates over compundKey list and updates glance information of all notification
// items. Also we update unread notification count as 0 for the user.
// If user's notifications are not cached, we just skip it. When an error occurrs
// we reset user's cache for preventing further error situations.
func (cache *NotificationCache) Glance(n *Notification) error {

	// user notification data is not cached
	if !cache.isCached(n.AccountId) {
		return nil
	}

	compoundKeys, err := cache.fetchSortedCompoundKeys(n.AccountId)
	if err != nil {
		cache.resetCache(n.AccountId)
		return err
	}

	for _, compoundKey := range compoundKeys {
		hashSetKey := cache.appendCachePrefix(compoundKey)
		newSetValueMap := map[string]interface{}{
			"glanced": true,
		}
		if err := cache.redisConn.HashMultipleSet(hashSetKey, newSetValueMap); err != nil {
			cache.resetCache(n.AccountId)
			return err
		}
	}

	unreadCountKey := cache.getAccountCacheKeyWithSuffix(n.AccountId, NotificationUnreadKey)

	return cache.redisConn.Set(unreadCountKey, "0")
}

// updateUnreadCount iterates over compoundKey list, fetches cached notification info
// and calculates unread count related to the glanced information.
func (cache *NotificationCache) updateUnreadCount(accountId int64) error {
	compoundKeys, err := cache.fetchSortedCompoundKeys(accountId)
	if err != nil {
		return err
	}

	unreadCount := 0
	for _, compoundKey := range compoundKeys {
		hashSetKey := cache.appendCachePrefix(compoundKey)

		reply, err := cache.redisConn.GetHashMultipleSet(hashSetKey, "glanced")
		if err != nil {
			return err
		}

		glanced, err := cache.redisConn.Bool(reply[0])
		if err != nil {
			return err
		}
		if !glanced {
			unreadCount++
		}
	}

	unreadCountKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationUnreadKey)

	return cache.redisConn.Set(unreadCountKey, strconv.Itoa(unreadCount))
}

// fetchSortedCompoundKeys fetches compoundKeys and sort notifications related to updatedAt
// field.
func (cache *NotificationCache) fetchSortedCompoundKeys(accountId int64) ([]string, error) {
	notificationIdList := make([]string, 0)

	listContainerKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationListKey)
	suffix := "*:" + NotificationUpdatedAtKey
	sortKey := cache.appendCachePrefix(suffix)
	compoundKeys, err := cache.redisConn.SortBy(listContainerKey, sortKey, "DESC")
	if err != nil {
		return notificationIdList, err
	}

	for _, compoundKey := range compoundKeys {
		memberValue, err := cache.redisConn.String(compoundKey)
		if err != nil {
			return notificationIdList, err
		}
		notificationIdList = append(notificationIdList, memberValue)
	}

	return notificationIdList, nil
}

// isCached checks whether the user has cached notification information
func (cache *NotificationCache) isCached(accountId int64) bool {
	listContainerKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationListKey)

	return cache.redisConn.Exists(listContainerKey)
}

// updateCompoundKeyList adds received notification's compoundKey to users compoundKeyList
// returns true if it is a new key.
func (cache *NotificationCache) updateCompoundKeyList(n *Notification, nc *NotificationContent) (bool, error) {
	listContainerKey := cache.getAccountCacheKeyWithSuffix(n.AccountId, NotificationListKey)
	memberKey := cache.getListMemberKey(n.AccountId, nc.TargetId, nc.TypeConstant)

	reply, err := cache.redisConn.AddSetMembers(listContainerKey, memberKey)
	if err != nil {
		return false, err
	}

	return reply > 0, nil
}

// addNotificationDetails
func (cache *NotificationCache) addNotificationDetails(n *Notification, nc *NotificationContent) error {
	// nt, err := CreateNotificationContentType(nc.TypeConstant)
	// if err != nil {
	// 	return err
	// }

	// nt.SetTargetId(nc.TargetId)
	// nt.SetListerId(n.AccountId)
	// ac, err := nt.FetchActors()
	// if err != nil {
	// 	return err
	// }

	nContainer := NewNotificationContainer()
	// nContainer.TypeConstant = nc.TypeConstant
	// nContainer.TargetId = nc.TargetId
	// nContainer.Glanced = false
	// nContainer.LatestActors = ac.LatestActors
	// nContainer.ActorCount = ac.Count
	// nContainer.UpdatedAt = n.UpdatedAt

	return cache.addNotification(nContainer, n.AccountId)
}

// updateDate updates notifications's updatedAt field.
func (cache *NotificationCache) updateDate(n *Notification, nc *NotificationContent) error {
	key := cache.getNotificationCacheKey(n.AccountId, nc.TargetId, nc.TypeConstant)
	updatedAtKey := key + ":" + NotificationUpdatedAtKey
	updatedAt := strconv.FormatInt(n.ActivatedAt.UnixNano(), 10)

	return cache.redisConn.Set(updatedAtKey, updatedAt)
}

// removeOldestItem removes the oldest notification item from cache if notification size is exceeded
// for the user.
func (cache *NotificationCache) removeOldestItem(n *Notification, nc *NotificationContent) error {
	compoundKeys, err := cache.fetchSortedCompoundKeys(n.AccountId)
	if err != nil {
		return err
	}

	if len(compoundKeys) <= cache.NotificationLimit {
		return nil
	}
	// remove the last one from list if it exceeds limits
	obsoleteKey := compoundKeys[cache.NotificationLimit]
	listContainerKey := cache.getAccountCacheKeyWithSuffix(n.AccountId, NotificationListKey)
	_, err = cache.redisConn.RemoveSetMembers(listContainerKey, obsoleteKey)
	if err != nil {
		return err
	}

	accountId, targetId, typeConstant, err := cache.parseCompoundKey(obsoleteKey)
	if err != nil {
		return err
	}

	// remove related data
	return cache.removeNotification(accountId, targetId, typeConstant)
}

// parseCompoundKey parses given compound key (account-{id}:{typeConstant}-{targetId})
// and returns accountId, targetId and typeConstant
func (cache *NotificationCache) parseCompoundKey(compoundKey string) (int64, int64, string, error) {
	splittedKey := strings.Split(compoundKey, ":")
	if len(splittedKey) != 2 {
		return 0, 0, "", fmt.Errorf("wrong compound key %s", compoundKey)
	}

	accountKey := splittedKey[0]
	splittedAccountKey := strings.Split(accountKey, "-")
	if len(splittedAccountKey) != 2 {
		return 0, 0, "", fmt.Errorf("wrong account key %s", splittedAccountKey)
	}

	accountId, err := strconv.ParseInt(splittedAccountKey[1], 10, 64)
	if err != nil {
		return 0, 0, "", err
	}

	notificationKey := splittedKey[1]
	splittedNotificationKey := strings.Split(notificationKey, "-")
	if len(splittedNotificationKey) != 2 {
		return 0, 0, "", fmt.Errorf("wrong notification key %s", splittedNotificationKey)
	}

	typeConstant := splittedNotificationKey[0]
	targetId, err := strconv.ParseInt(splittedNotificationKey[1], 10, 64)
	if err != nil {
		return 0, 0, "", nil
	}

	return accountId, targetId, typeConstant, nil
}

// removeNotification removes notification hashset and updatedAt value from cache
func (cache *NotificationCache) removeNotification(accountId, targetId int64, typeConstant string) error {
	key := cache.getNotificationCacheKey(accountId, targetId, typeConstant)
	updatedAtKey := key + ":" + NotificationUpdatedAtKey
	_, err := cache.redisConn.Del(key, updatedAtKey)

	return err
}

// populateNotificationContainer gets compoundKey (account-{id}:{typeConstant}-{targetId})
// fetches all NotificationContainer data with this key and populates the notification
// container instance
func (cache *NotificationCache) populateNotificationContainer(compoundKey string, nc *NotificationContainer) error {
	accountId, targetId, typeConstant, err := cache.parseCompoundKey(compoundKey)
	if err != nil {
		return err
	}

	itemKey := cache.appendCachePrefix(compoundKey)

	nc.UpdatedAt, err = cache.getUpdatedAt(itemKey)
	if err != nil {
		return err
	}

	nc.TypeConstant = typeConstant
	nc.TargetId = targetId

	return cache.populateNotificationDetails(accountId, nc)
}

// populateNotificationDetails fetches glance, ActorCount, LatestActors information
// from cache and populates it to NotificationContainer instance
// key: {environment}:notification:account-{accountId}:{typeConstant}-{targetId}
func (cache *NotificationCache) populateNotificationDetails(accountId int64, nc *NotificationContainer) error {
	itemKey := cache.getNotificationCacheKey(accountId, nc.TargetId, nc.TypeConstant)
	fields := cache.getCacheFields()
	// TODO what if the values are new and not existing
	values, err := cache.redisConn.GetHashMultipleSet(itemKey, fields...)
	if err != nil {
		return err
	}

	nc.Glanced, err = cache.redisConn.Bool(values[0])
	if err != nil {
		return err
	}

	nc.ActorCount, err = cache.redisConn.Int(values[1])
	if err != nil {
		return err
	}

	for i := 2; i < len(values); i++ {
		actor, err := cache.redisConn.Int64(values[i])
		if err == nil {
			nc.LatestActors = append(nc.LatestActors, actor)
		}
	}

	return nil
}

// fetUpdatedAt retrievec updated at data of the notification and converts it
// to Time
func (cache *NotificationCache) getUpdatedAt(key string) (time.Time, error) {
	updatedAtKey := fmt.Sprintf("%s:%s", key, NotificationUpdatedAtKey)

	updatedAtValue, err := cache.redisConn.GetInt(updatedAtKey)
	if err != nil {
		return time.Now(), err
	}

	return time.Unix(0, int64(updatedAtValue)), nil
}

// appendCachePrefix appends {environment}:notification prefix to the given suffix
func (cache *NotificationCache) appendCachePrefix(suffix string) string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		NotificationKey,
		suffix,
	)
}

// getAccountCacheKey returns account key with prefix
// result: {environment}:notification:account-{id}
func (cache *NotificationCache) getAccountCacheKey(accountId int64) string {
	suffix := fmt.Sprintf("%s-%d", NotificationAccountKey, accountId)
	return cache.appendCachePrefix(suffix)
}

// getNotificationCacheKey returns notification key with prefix
// result: {environment}:notification:account-{id}:{typeConstant}-{targetId}
func (cache *NotificationCache) getNotificationCacheKey(accountId, targetId int64, typeConstant string) string {
	prefix := cache.getAccountCacheKey(accountId)
	return fmt.Sprintf(
		"%s:%s-%d",
		prefix,
		typeConstant,
		targetId,
	)
}

// getAccountKeyWithSuffix returns notification key with appended suffix
// result: {environment}:notification:account-{id}:{suffix}
func (cache *NotificationCache) getAccountCacheKeyWithSuffix(accountId int64, suffix string) string {
	prefix := cache.getAccountCacheKey(accountId)
	return fmt.Sprintf(
		"%s:%s",
		prefix,
		suffix,
	)
}

// getListMemberKey returns notification keys without prefixes
// result: account-{id}:{typeConstant}-{targetId}
func (cache *NotificationCache) getListMemberKey(accountId int64, targetId int64, typeConstant string) string {
	return fmt.Sprintf(
		"%s-%d:%s-%d",
		NotificationAccountKey,
		accountId,
		typeConstant,
		targetId,
	)
}

func (cache *NotificationCache) UpdateCachedNotifications(accountId int64, nr *NotificationResponse) error {
	listKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationListKey)
	_, err := cache.redisConn.Del(listKey)
	if err != nil {
		return err
	}

	listItemIds := make([]interface{}, 0)
	for _, nc := range nr.Notifications {
		if err := cache.addNotification(&nc, accountId); err != nil {
			return err
		}

		listItemKey := cache.getListMemberKey(accountId, nc.TargetId, nc.TypeConstant)
		listItemIds = append(listItemIds, listItemKey)
	}

	// update object lister
	if _, err := cache.redisConn.AddSetMembers(listKey, listItemIds...); err != nil {
		return err
	}

	// update unread count
	unreadKey := cache.getAccountCacheKeyWithSuffix(accountId, NotificationUnreadKey)
	if err := cache.redisConn.Set(unreadKey, strconv.Itoa(nr.UnreadCount)); err != nil {
		return err
	}

	return nil
}

func (cache *NotificationCache) addNotification(nc *NotificationContainer, accountId int64) error {
	itemKey := cache.getNotificationCacheKey(accountId, nc.TargetId, nc.TypeConstant)
	if err := cache.updateCacheItemModifiedDate(nc, itemKey); err != nil {
		return err
	}

	if err := cache.updateCachedItem(nc, itemKey); err != nil {
		return err
	}

	return nil
}

func (cache *NotificationCache) updateCacheItemModifiedDate(nc *NotificationContainer, prefix string) error {
	prefix = fmt.Sprintf("%s:%s", prefix, NotificationUpdatedAtKey)

	return cache.redisConn.Set(prefix, strconv.FormatInt(nc.UpdatedAt.UnixNano(), 10))
}

func (cache *NotificationCache) updateCachedItem(nc *NotificationContainer, prefix string) error {
	instance := map[string]interface{}{
		"glanced":    nc.Glanced,
		"actorCount": nc.ActorCount,
	}

	for index, val := range nc.LatestActors {
		key := fmt.Sprintf("%s-%d", NotificationActorKey, index)
		instance[key] = val
	}

	return cache.redisConn.HashMultipleSet(prefix, instance)
}

func (cache *NotificationCache) getCacheFields() []interface{} {
	fields := []interface{}{"glanced", "actorCount"}
	for i := 0; i < cache.ActorLimit; i++ {
		actorField := fmt.Sprintf("%s-%d", NotificationActorKey, i)
		fields = append(fields, actorField)
	}

	return fields
}

func (cache *NotificationCache) resetCache(accountId int64) error {
	prefix := cache.getAccountCacheKeyWithSuffix(accountId, "*")
	// TODO instead of using Keys use stored values in set :list
	// members, err := RedisConn.GetSetMembers(key)
	keys, err := cache.redisConn.Keys(prefix)

	if err != nil {
		return err
	}

	deletedKeys := make([]interface{}, 0)
	for _, key := range keys {
		deleteKey, err := cache.redisConn.String(key)
		if err == nil {
			deletedKeys = append(deletedKeys, deleteKey)
		}
	}

	_, err = cache.redisConn.Del(deletedKeys...)
	if err != nil {
		fmt.Println("cache cannot be reset") // todolog
	}

	return err
}
