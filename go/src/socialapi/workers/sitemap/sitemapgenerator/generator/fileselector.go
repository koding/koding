package generator

import (
	"socialapi/workers/helper"
	"socialapi/workers/sitemap"

	"github.com/garyburd/redigo/redis"
)

type FileSelector interface {
	Select() (string, error)
}

type SimpleFileSelector struct{}

func (s SimpleFileSelector) Select() (string, error) {
	return "sitemap", nil
}

type CachedFileSelector struct{}

func (s CachedFileSelector) Select() (string, error) {
	redisConn := helper.MustGetRedisConn()

	item, err := redisConn.PopSetMember(sitemap.PrepareFileNameCacheKey())

	if err != nil && err != redis.ErrNil {
		return "", err
	}

	return item, err
}
