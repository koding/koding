package testhelper

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/email/privatemessageemail/common"

	"github.com/koding/redis"
)

func deleteKeys(redisConn *redis.RedisSession, pattern string) {
	keys, _ := redisConn.Keys(pattern)

	for _, key := range keys {
		val, _ := redisConn.String(key)
		redisConn.Del(val)
	}
}

func ResetCache(redisConn *redis.RedisSession) {
	redisConn.Del(common.AccountNextPeriodHashSetKey())
	deleteKeys(redisConn, allPeriodAccountSetKey())
	deleteKeys(redisConn, AllAccountChannelHashSetKey())
}

func AllAccountChannelHashSetKey() string {
	return fmt.Sprintf("%s:%s:%s:*",
		config.MustGet().Environment,
		common.CachePrefix,
		"account-channelhashset",
	)
}

func allPeriodAccountSetKey() string {
	return fmt.Sprintf("%s:%s:%s:*",
		config.MustGet().Environment,
		common.CachePrefix,
		"periodaccountset",
	)
}
