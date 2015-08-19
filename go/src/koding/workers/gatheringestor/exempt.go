package main

import "github.com/koding/redis"

// isInExemptList returns if user is in exempt list of users for
// stopping their VMs.
func isInExemptList(conn *redis.RedisSession, username string) (bool, error) {
	i, err := conn.IsSetMember(ExemptUsersKey, username)
	return i == 1, err
}
