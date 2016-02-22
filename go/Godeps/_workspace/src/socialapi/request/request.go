package request

import (
	"net/url"
	"strconv"
)

func GetId(u *url.URL) (int64, error) {
	return GetURIInt64(u, "id")
}

func GetURIInt64(u *url.URL, queryParam string) (int64, error) {
	val := u.Query().Get(queryParam)

	if val == "" || val == "0" {
		return 0, nil
	}

	return strconv.ParseInt(val, 10, 64)
}

func GetQuery(u *url.URL) *Query {
	return NewQuery().MapURL(u).SetDefaults()
}
