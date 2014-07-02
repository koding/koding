package generator

import (
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
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

	item, err := redisConn.PopSetMember(common.PrepareCurrentFileNameCacheKey())

	if err != nil {
		return "", err
	}

	return item, nil
}
