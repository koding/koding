package main

import (
	"fmt"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

type Storage interface {
	Save(string, string, float64) error
	Get(string, string) (float64, error)
}

var (
	storage Storage

	WorkerName = "cloudwatch"
	GroupBy    = "users"
)

type RedisStorage struct {
	Client *redis.RedisSession
}

func (r *RedisStorage) Save(metricName, username string, value float64) error {
	return r.Client.SortedSetAddSingle(r.Key(metricName), username, value)
}

func (r *RedisStorage) Get(metricName, username string) (float64, error) {
	return r.Client.SortedSetScore(r.Key(metricName), username)
}

func (r *RedisStorage) Key(prefix string) string {
	year, week := now.BeginningOfWeek().ISOWeek()
	return fmt.Sprintf("%s:%s:%s:%d-%d", WorkerName, prefix, GroupBy, year, week)
}
