package algoliasearch

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
)

// GenerateSecuredAPIKey generates a public API key intended to restrict access
// to certain records. This new key is built upon the existing key named
// `apiKey` and the `params` map. The `params` map can contain any query
// parameters to restrict what needs to be and can also have the following
// fields:
//   - `userToken` (string identifier generally used to rate-limit users per IP)
//   - `validUntil` (timestamp of the expiration date)
//   - `restrictIndices` (comma-separated string list of the indices to restrict)
//   - `referers` (string slice of allowed referers)
//   - `restrictSources` (string of the allowed IPv4 network)
//
// More details here:
// https://www.algolia.com/doc/rest-api/search/#request-from-browser-with-secure-restriction
func GenerateSecuredAPIKey(apiKey string, params Map) (key string, err error) {
	if err = checkGenerateSecuredAPIKey(params); err != nil {
		return
	}

	message := encodeMap(params)

	h := hmac.New(sha256.New, []byte(apiKey))
	h.Write([]byte(message))
	securedKey := hex.EncodeToString(h.Sum(nil))

	key = base64.StdEncoding.EncodeToString([]byte(securedKey + message))
	return
}
