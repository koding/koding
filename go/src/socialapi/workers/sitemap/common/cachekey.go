package common

import (
	"fmt"
	"socialapi/config"
	"strconv"
	"time"
)

const (
	CACHEPREFIX = "sitemap"
	TIMERANGE   = 30
)

func PrepareFileCacheKey(fileName string) string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		fileName,
	)
}

func PrepareNextFileNameCacheKey() string {
	// divide time range into segments (for 30m range segment can be 0 or 1)
	segment := time.Now().Minute() / TIMERANGE
	segment = (segment + 1) % (60 / TIMERANGE)

	return prepareFileNameCacheKey(strconv.Itoa(segment))
}

func PreparePrevFileNameCacheKey() string {
	segment := time.Now().Minute() / TIMERANGE

	return prepareFileNameCacheKey(strconv.Itoa(segment))
}

func prepareFileNameCacheKey(segment string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		segment,
		"fileNames",
	)
}
