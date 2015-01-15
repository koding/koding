package main

import (
	"fmt"
	"strconv"

	"github.com/jinzhu/now"
	"github.com/koding/redis"
)

type NewStorage interface {
	//string
	Upsert(string, float64) error
	Get(string) (float64, error)

	//set
	Save(string, ...interface{}) error
	Pop(string) (string, error)
	Exists(string, string) (bool, error)

	// zset
	GetScore(string, string) (float64, error)
	SaveScore(string, string, float64) error
	UpsertScore(string, string, float64) error
	GetFromScore(string, float64) ([]string, error)
}

type NewRedisStorage struct {
	Client *redis.RedisSession
}

//----------------------------------------------------------
// STRING
//----------------------------------------------------------

func (r *NewRedisStorage) Upsert(key string, value float64) error {
	_, err := r.Client.Get(r.prefix(key))
	if err != nil && !isRedisRecordNil(err) {
		return err
	}

	if isRedisRecordNil(err) {
		return r.Client.Set(r.prefix(key), fmt.Sprintf("%v", value))
	}

	return nil
}

func (r *NewRedisStorage) Get(key string) (float64, error) {
	existingLimitStr, err := r.Client.Get(r.prefix(key))
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

func (r *NewRedisStorage) Save(key string, members ...interface{}) error {
	_, err := r.Client.AddSetMembers(r.prefix(key), members...)
	return err
}

func (r *NewRedisStorage) Pop(key string) (string, error) {
	return r.Client.PopSetMember(r.prefix(key))
}

func (r *NewRedisStorage) Exists(key, member string) (bool, error) {
	yes, err := r.Client.IsSetMember(r.prefix(key), member)
	if err != nil {
		return false, err
	}

	return yes == 1, nil
}

//----------------------------------------------------------
// ZSET
//----------------------------------------------------------

func (r *NewRedisStorage) SaveScore(key, member string, score float64) error {
	return r.Client.SortedSetAddSingle(r.weekPrefix(key), member, score)
}

func (r *NewRedisStorage) GetScore(key, member string) (float64, error) {
	return r.Client.SortedSetScore(r.weekPrefix(key), member)
}

func (r *NewRedisStorage) UpsertScore(key, member string, score float64) error {
	_, err := r.GetScore(key, member)
	if err != nil && !isRedisRecordNil(err) {
		return err
	}

	if isRedisRecordNil(err) {
		return r.SaveScore(key, member, score)
	}

	return nil
}

func (r *NewRedisStorage) GetFromScore(key string, from float64) ([]string, error) {
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

func (r *NewRedisStorage) prefix(key string) string {
	return fmt.Sprintf("%s:%s", WorkerName, key)
}

func (r *NewRedisStorage) weekPrefix(key string) string {
	year, week := now.BeginningOfWeek().ISOWeek()
	return fmt.Sprintf("%s:%d:%d:%s", WorkerName, year, week, key)
}

func (r *NewRedisStorage) hourPrefix(key string) string {
	t := now.BeginningOfHour()

	year, month, day := t.Date()
	hour := t.Hour()

	return fmt.Sprintf("%s:%d:%s:%d-%d-%s",
		WorkerName, year, month, day, hour, key,
	)
}
