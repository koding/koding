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

func PrepareCurrentFileCacheKey(fileName string) string {
	return prepareFileCacheKey(getCurrentSegment(), fileName)
}

func PrepareNextFileCacheKey(fileName string) string {
	return prepareFileCacheKey(getNextSegment(), fileName)
}

func prepareFileCacheKey(segment, fileName string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		segment,
		fileName,
	)
}

func PrepareNextFileNameCacheKey() string {
	return prepareFileNameCacheKey(getNextSegment())
}

func PrepareCurrentFileNameCacheKey() string {
	return prepareFileNameCacheKey(getCurrentSegment())
}

func prepareFileNameCacheKey(segment string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		segment,
		"fileNames",
	)
}

func getCurrentSegment() string {
	segment := time.Now().Minute() / TIMERANGE

	return strconv.Itoa(segment)
}

func getNextSegment() string {
	// divide time range into segments (for 30m range segment can be 0 or 1)
	segment := time.Now().Minute() / TIMERANGE
	segment = (segment + 1) % (60 / TIMERANGE)

	return strconv.Itoa(segment)
}
