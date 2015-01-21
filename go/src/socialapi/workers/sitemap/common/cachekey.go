package common

import (
	"fmt"
	"socialapi/config"
	"strconv"
	"time"
)

const (
	CACHEPREFIX = "sitemap"
)

func PrepareCurrentFileCacheKey(fileName string, timeInterval int) string {
	return prepareFileCacheKey(getCurrentSegment(timeInterval), fileName)
}

// PrepareNextFileCacheKey gets the cache key for upcoming updates
func PrepareNextFileCacheKey(fileName string, timeInterval int) string {
	return prepareFileCacheKey(getNextSegment(timeInterval), fileName)
}

func prepareFileCacheKey(segment, fileName string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		segment,
		fileName,
	)
}

func PrepareNextFileNameSetCacheKey(timeInterval int) string {
	return prepareFileNameSetCacheKey(getNextSegment(timeInterval))
}

func PrepareCurrentFileNameSetCacheKey(timeInterval int) string {
	return prepareFileNameSetCacheKey(getCurrentSegment(timeInterval))
}

func prepareFileNameSetCacheKey(segment string) string {
	return fmt.Sprintf("%s:%s:%s:%s",
		config.MustGet().Environment,
		CACHEPREFIX,
		segment,
		"fileNames",
	)
}

func getCurrentSegment(timeInterval int) string {
	segment := time.Now().Minute() / timeInterval

	return strconv.Itoa(segment)
}

func getNextSegment(timeInterval int) string {
	// divide time range into segments (for 30m range segment can be 0 or 1)

	segment := time.Now().Minute() / timeInterval
	segment = (segment + 1) % (60 / timeInterval)

	return strconv.Itoa(segment)
}
