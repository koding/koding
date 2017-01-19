package algoliasearch

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/url"
	"strconv"
	"time"
)

// randDuration generates a pseudo-random `time.Duration` between 1 and `max`.
func randDuration(max time.Duration) time.Duration {
	rand.Seed(time.Now().Unix())
	nbNanoseconds := 1 + int(rand.Int63n(max.Nanoseconds()))
	return time.Duration(nbNanoseconds) * time.Nanosecond
}

func invalidType(p, t string) error {
	return fmt.Errorf("`%s` should be of type `%s`", p, t)
}

func duplicateMap(m Map) Map {
	copy := make(Map)

	for k, v := range m {
		copy[k] = v
	}

	return copy
}

// encodeMap transforms `params` to a URL-safe string.
func encodeMap(params Map) string {
	values := url.Values{}

	if params != nil {
		for k, v := range params {
			switch v := v.(type) {
			case string:
				values.Add(k, v)
			case float64:
				values.Add(k, strconv.FormatFloat(v, 'f', -1, 64))
			case int:
				values.Add(k, strconv.Itoa(v))
			default:
				jsonValue, _ := json.Marshal(v)
				values.Add(k, string(jsonValue[:]))
			}
		}
	}

	return values.Encode()
}
