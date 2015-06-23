package main

import (
	"fmt"
	"strconv"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

type Storage interface {
	//string
	Upsert(string, string, float64) error
	Get(string, string) (float64, error)

	//set
	Save(string, string, []interface{}) error
	Pop(string, string) (string, error)
	Exists(string, string, string) (bool, error)

	//zset for per user score
	GetScore(string, string) (float64, error)
	SaveScore(string, string, float64) error
	GetFromScore(string, float64) ([]string, error)

	//hash for per user limit
	SaveUserLimit(string, float64) error
	GetUserLimit(string) (float64, error)
	RemoveUserLimit(string) error
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
	return r.Client.SortedSetAddSingle(r.usersPrefix(key), member, score)
}

func (r *RedisStorage) GetScore(key, member string) (float64, error) {
	return r.Client.SortedSetScore(r.usersPrefix(key), member)
}

func (r *RedisStorage) GetFromScore(key string, from float64) ([]string, error) {
	rawMembers, err := r.Client.SortedSetRangebyScore(r.usersPrefix(key), from, redis.PositiveInf)
	if err != nil {
		return nil, err
	}

	members := []string{}
	for _, member := range rawMembers {
		members = append(members, string(member.([]uint8)))
	}

	return members, nil
}

func (r *RedisStorage) SaveUserLimit(member string, limit float64) error {
	_, err := r.Client.HashSet(r.userLimitPrefix(), member, limit)
	return err
}

func (r *RedisStorage) GetUserLimit(member string) (float64, error) {
	limitStr, err := r.Client.GetHashSetField(r.userLimitPrefix(), member)
	if err != nil {
		return 0, err
	}

	limit, err := strconv.ParseFloat(limitStr, 64)
	if err != nil {
		return 0, err
	}

	return limit, nil
}

func (r *RedisStorage) RemoveUserLimit(member string) error {
	_, err := r.Client.DeleteHashSetField(r.userLimitPrefix(), member)
	return err
}

//----------------------------------------------------------
// Prefix helpers
//----------------------------------------------------------

func (r *RedisStorage) userLimitPrefix() string {
	return r.prefix("users", "limit")
}

func (r *RedisStorage) usersPrefix(key string) string {
	return r.weekPrefix(key + ":users")
}

func (r *RedisStorage) prefix(key, subkey string) string {
	return fmt.Sprintf("%s:%s:%s", WorkerName, key, subkey)
}

func (r *RedisStorage) weekPrefix(key string) string {
	year, week := now.BeginningOfWeek().ISOWeek()
	return fmt.Sprintf("%s:%s:%d-%d", WorkerName, key, year, week)
}

func (r *RedisStorage) hourPrefix(key string) string {
	t := now.BeginningOfHour()

	year, month, day := t.Date()
	hour := t.Hour()

	return fmt.Sprintf("%s:%d:%s:%d-%d-%s",
		WorkerName, year, month, day, hour, key,
	)
}
