package main

import (
	"fmt"
	"strconv"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

var storage Storage

type Storage interface {
	//string
	Upsert(string, string, float64) error
	Get(string, string) (float64, error)

	//set
	Save(string, string, []interface{}) error
	Pop(string, string) (string, error)
	Exists(string, string, string) (bool, error)

	//zset
	GetScore(string, string) (float64, error)
	SaveScore(string, string, float64) error
	GetFromScore(string, float64) ([]string, error)
}

type RedisStorage struct {
	Client *redis.RedisSession
}

//----------------------------------------------------------
// STRING
//----------------------------------------------------------

func (r *RedisStorage) Upsert(key, subkey string, value float64) error {
	_, err := r.Client.Get(r.prefix(key, subkey))
	if err != nil && !isRedisRecordNil(err) {
		return err
	}

	if isRedisRecordNil(err) {
		return r.Client.Set(r.prefix(key, subkey), fmt.Sprintf("%v", value))
	}

	return nil
}

func (r *RedisStorage) Get(key, subkey string) (float64, error) {
	existingLimitStr, err := r.Client.Get(r.prefix(key, subkey))
	if err != nil && !isRedisRecordNil(err) {
		return 0, err
	}

	existingLimit, err := strconv.ParseFloat(existingLimitStr, 64)
	if err != nil {
		return 0, err
	}

	return existingLimit, nil
}

//----------------------------------------------------------
// SET
//----------------------------------------------------------

func (r *RedisStorage) Save(key, subkey string, members []interface{}) error {
	if len(members) == 0 {
		return nil
	}

	_, err := r.Client.AddSetMembers(r.prefix(key, subkey), members...)
	return err
}

func (r *RedisStorage) Pop(key, subkey string) (string, error) {
	return r.Client.PopSetMember(r.prefix(key, subkey))
}

func (r *RedisStorage) Exists(key, subkey, member string) (bool, error) {
	yes, err := r.Client.IsSetMember(r.prefix(key, subkey), member)
	if err != nil {
		return false, err
	}

	return yes == 1, nil
}

//----------------------------------------------------------
// ZSET
//----------------------------------------------------------

func (r *RedisStorage) SaveScore(key, member string, score float64) error {
	return r.Client.SortedSetAddSingle(r.weekPrefix(key), member, score)
}

func (r *RedisStorage) GetScore(key, member string) (float64, error) {
	return r.Client.SortedSetScore(r.weekPrefix(key), member)
}

func (r *RedisStorage) UpsertScore(key, member string, score float64) error {
	_, err := r.GetScore(key, member)
	if err != nil && !isRedisRecordNil(err) {
		return err
	}

	if isRedisRecordNil(err) {
		return r.SaveScore(key, member, score)
	}

	return nil
}

func (r *RedisStorage) GetFromScore(key string, from float64) ([]string, error) {
	rawMembers, err := r.Client.SortedSetRangebyScore(r.weekPrefix(key), from, redis.PositiveInf)
	if err != nil {
		return nil, err
	}

	members := []string{}
	for _, member := range rawMembers {
		members = append(members, string(member.([]uint8)))
	}

	return members, nil
}

//----------------------------------------------------------
// Prefix helpers
//----------------------------------------------------------

func (r *RedisStorage) prefix(key, subkey string) string {
	return fmt.Sprintf("%s:%s:%s", WorkerName, key, subkey)
}

func (r *RedisStorage) weekPrefix(key string) string {
	year, week := now.BeginningOfWeek().ISOWeek()
	return fmt.Sprintf("%s:%d:%d:%s", WorkerName, year, week, key)
}

func (r *RedisStorage) hourPrefix(key string) string {
	t := now.BeginningOfHour()

	year, month, day := t.Date()
	hour := t.Hour()

	return fmt.Sprintf("%s:%d:%s:%d-%d-%s",
		WorkerName, year, month, day, hour, key,
	)
}
