package main

import (
	"fmt"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

type Storage interface {
	Queue(string, []interface{}) error
	Pop(string) (string, error)
	Range(string, int) ([]string, error)
	Save(string, string, float64) error
	Get(string, string) (float64, error)
}

var (
	storage Storage

	WorkerName = "cloudwatch"
	GroupBy    = "users"
	QueueName  = "queue"

	NetworkOutLimt = 7
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

func (r *RedisStorage) Range(metricName string, min int) ([]string, error) {
	raw, err := r.Client.SortedSetRangebyScore(r.Key(metricName), min, "+inf")
	if err != nil {
		return nil, err
	}

	usernames := []string{}
	for _, username := range raw {
		usernames = append(usernames, string(username.([]uint8)))
	}

	return usernames, nil
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
