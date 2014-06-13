package sitemap

import (
	"fmt"
	"socialapi/config"
)

const (
	CACHEPREFIX = "sitemap"
)

func PrepareFileCacheKey(fileName string) string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		fileName,
	)
}

func PrepareFileNameCacheKey() string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		"fileNames",
	)
}
