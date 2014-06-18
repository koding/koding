package request

import (
	"net/url"
	"strconv"
)

func GetId(u *url.URL) (int64, error) {
	return strconv.ParseInt(u.Query().Get("id"), 10, 64)
}

func GetURIInt64(u *url.URL, queryParam string) (int64, error) {
	return strconv.ParseInt(u.Query().Get(queryParam), 10, 64)
}

func GetQuery(u *url.URL) *Query {
	return NewQuery().MapURL(u).SetDefaults()
}
