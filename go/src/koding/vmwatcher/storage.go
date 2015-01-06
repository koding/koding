package main

import (
	"fmt"
	"strconv"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

type Storage interface {
	Queue(string, []interface{}) error
	Pop(string) (string, error)
	Remove(string, string) error
	Range(string, float64) ([]string, error)
	Save(string, string, float64) error
	Get(string, string) (float64, error)
	ExemptGet(string, string) (bool, error)
	ExemptSave(string, []interface{}) error
	SaveLimitUnlessExists(string, float64) error
	GetLimit(string, float64) (float64, error)
}

var (
	storage Storage

	// redis key prefixes
	GroupBy   = "users"
	QueueName = "queue"
	ExemptKey = "exempt"
	LimitKey  = "limit"
)

type RedisStorage struct {
	Client *redis.RedisSession
}

func (r *RedisStorage) Queue(metricName string, usernames []interface{}) error {
	_, err := r.Client.AddSetMembers(r.QueueKey(metricName), usernames...)
	return err
}

func (r *RedisStorage) Pop(metricName string) (string, error) {
	return r.Client.PopSetMember(r.QueueKey(metricName))
}

func (r *RedisStorage) Save(metricName, username string, value float64) error {
	return r.Client.SortedSetAddSingle(r.Key(metricName), username, value)
}

func (r *RedisStorage) Get(metricName, username string) (float64, error) {
	return r.Client.SortedSetScore(r.Key(metricName), username)
}

func (r *RedisStorage) Range(metricName string, min float64) ([]string, error) {
	raw, err := r.Client.SortedSetRangebyScore(r.Key(metricName), min, redis.PositiveInf)
	if err != nil {
		return nil, err
	}

	usernames := []string{}
	for _, username := range raw {
		usernames = append(usernames, string(username.([]uint8)))
	}

	return usernames, nil
}

func (r *RedisStorage) ExemptSave(prefix string, usernames []interface{}) error {
	_, err := r.Client.AddSetMembers(r.ExemptKey(prefix), usernames...)
	return err
}

func (r *RedisStorage) ExemptGet(prefix, username string) (bool, error) {
	yes, err := r.Client.IsSetMember(r.ExemptKey(prefix), username)
	if err != nil {
		return false, err
	}

	switch yes {
	case 0:
		return false, nil
	case 1:
		return true, nil
	}

	return false, nil
}

func (r *RedisStorage) Remove(prefix, username string) error {
	_, err := r.Client.RemoveSetMembers(r.Key(prefix), username)
	return err
}

func (r *RedisStorage) GetLimit(prefix string, defaultLimit float64) (float64, error) {
	existingLimitStr, err := r.Client.Get(r.LimitKey(prefix))
	if err != nil && !isRedisRecordNil(err) {
		return defaultLimit, err
	}

	if isRedisRecordNil(err) {
		Log.Error("Fetching limit for metric: %s returned nil", prefix)
		return defaultLimit, nil
	}

	existingLimit, err := strconv.ParseFloat(existingLimitStr, 64)
	if err != nil {
		Log.Error("Marshalling limit fetched by db failed: %v", existingLimit)
		return defaultLimit, nil
	}

	Log.Info("Limit: %v for metric: %s", existingLimit, prefix)

	return existingLimit, nil
}

func (r *RedisStorage) SaveLimitUnlessExists(prefix string, limit float64) error {
	_, err := r.Client.Get(r.LimitKey(prefix))
	if err != nil && !isRedisRecordNil(err) {
		return err
	}

	if isRedisRecordNil(err) {
		Log.Info("No limit for metric: %s setting to default: %v", prefix, limit)

		err := r.Client.Set(r.LimitKey(prefix), fmt.Sprintf("%v", limit))
		if err != nil {
			return err
		}
	}

	return nil
}

func (r *RedisStorage) LimitKey(prefix string) string {
	return fmt.Sprintf("%s:%s:%s", WorkerName, prefix, LimitKey)
}

func (r *RedisStorage) ExemptKey(prefix string) string {
	return fmt.Sprintf("%s:%s:%s", WorkerName, prefix, ExemptKey)
}

func (r *RedisStorage) Key(prefix string) string {
	year, week := now.BeginningOfWeek().ISOWeek()
	return fmt.Sprintf("%s:%s:%s:%d-%d", WorkerName, prefix, GroupBy, year, week)
}

func (r *RedisStorage) QueueKey(prefix string) string {
	t := now.BeginningOfHour()

	year, month, day := t.Date()
	hour := t.Hour()

	return fmt.Sprintf("%s:%s:%s:%d-%s-%d-%d",
		WorkerName, prefix, QueueName, year, month, day, hour,
	)
}
