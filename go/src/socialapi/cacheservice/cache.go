package cacheservice

import (
	"socialapi/workers/helper"

	"github.com/garyburd/redigo/redis"
)

type cacher interface {
	Prefix(id int64) string
	Getter(id int64) (string, error)
	Setter(id int64, data interface{}) (string, error)
}

func Get(service cacher, id int64) (string, error) {
	data, err := helper.MustGetRedisConn().Get(service.Prefix(id))
	// if not err, return early
	if err == nil {
		return data, nil
	}

	// if error isnt nilErr, return
	if err != redis.ErrNil {
		return "", err
	}

	// try to get data from getter func
	d, err := service.Getter(id)
	if err != nil {
		return "", err
	}

	// after getting data, set it to cache
	// since we have the data, no need to handle error here
	put(service.Prefix(id), d)

	return d, nil
}

func Set(service cacher, id int64, data interface{}) error {
	d, err := service.Setter(id, data)
	if err != nil {
		return err
	}

	return put(service.Prefix(id), d)
}

func put(id, data string) error {
	return helper.MustGetRedisConn().Set(id, data)
}
