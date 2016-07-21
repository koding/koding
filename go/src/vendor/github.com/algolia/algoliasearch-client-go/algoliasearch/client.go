package algoliasearch

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"reflect"
	"strings"
	"time"
)

// Client is a representation of an Algolia application. Once initialized it
// allows manipulations over the indexes of the application as well as
// network related parameters.
type Client struct {
	transport *Transport
}

// NewClient creates a new Client from the provided `appID` and `apiKey`. The
// default hosts are used for the transport layer.
func NewClient(appID, apiKey string) *Client {
	return &Client{
		transport: NewTransport(appID, apiKey),
	}
}

// NewClientWithHosts creates a new Client from the provided `appID,` `apiKey`,
// and `hosts` used to connect to the Algolia servers.
func NewClientWithHosts(appID, apiKey string, hosts []string) *Client {
	return &Client{
		transport: NewTransportWithHosts(appID, apiKey, hosts),
	}
}

// SetExtraHeader allows to set custom headers while reaching out to
// Algolia servers.
func (c *Client) SetExtraHeader(key string, value string) {
	c.transport.setExtraHeader(key, value)
}

// SetTimeout specifies timeouts to use with the HTTP connection.
func (c *Client) SetTimeout(connectTimeout int, readTimeout int) {
	c.transport.setTimeout(time.Duration(connectTimeout)*time.Millisecond, time.Duration(readTimeout)*time.Millisecond)
}

// ListIndexes returns the list of all indexes belonging to this Algolia
// application.
func (c *Client) ListIndexes() (interface{}, error) {
	return c.transport.request("GET", "/1/indexes", nil, read)
}

// InitIndex returns an Index object targeting `indexName`.
func (c *Client) InitIndex(indexName string) *Index {
	return NewIndex(indexName, c)
}

// ListKeys returns all the API keys available for this Algolia application.
func (c *Client) ListKeys() (interface{}, error) {
	return c.transport.request("GET", "/1/keys", nil, read)
}

// MoveIndex renames the index named `source` as `destination`.
func (c *Client) MoveIndex(source string, destination string) (interface{}, error) {
	return c.InitIndex(source).Move(destination)
}

// CopyIndex duplicates the index named `source` as `destination`.
func (c *Client) CopyIndex(source string, destination string) (interface{}, error) {
	return c.InitIndex(source).Copy(destination)
}

// AddKey creates a new API key named `key` using the `acl` operation
// restrictions, the `indexes` the key is limited to, the `validity` during
// which the key is to be valid in seconds, `maxQueriesPerIPPerHour` and
// `maxHitsPerQuery` as rate limiters.
func (c *Client) AddKey(acl, indexes []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := map[string]interface{}{
		"acl":                    acl,
		"maxHitsPerQuery":        maxHitsPerQuery,
		"maxQueriesPerIPPerHour": maxQueriesPerIPPerHour,
		"validity":               validity,
		"indexes":                indexes,
	}

	return c.AddKeyWithParam(body)
}

// AddKeyWithParam creates a new API key using the specified
// parameters.
func (c *Client) AddKeyWithParam(params interface{}) (interface{}, error) {
	return c.transport.request("POST", "/1/keys/", params, read)
}

// UpdateKey updates the API key named `key` using the `acl` operation
// restrictions, the `indexes` the key is limited to, the `validity` during
// which the key is to be valid in seconds, `maxQueriesPerIPPerHour` and
// `maxHitsPerQuery` as rate limiters.
func (c *Client) UpdateKey(key string, acl, indexes []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := map[string]interface{}{
		"acl":                    acl,
		"maxHitsPerQuery":        maxHitsPerQuery,
		"maxQueriesPerIPPerHour": maxQueriesPerIPPerHour,
		"validity":               validity,
		"indexes":                indexes,
	}

	return c.UpdateKeyWithParam(key, body)
}

// UpdateKeyWithParam updates the API key named `key` with the supplied
// parameters.
func (c *Client) UpdateKeyWithParam(key string, params interface{}) (interface{}, error) {
	return c.transport.request("PUT", "/1/keys/"+key, params, write)
}

// GetKey returns the characteristics of the API key named `key`.
func (c *Client) GetKey(key string) (interface{}, error) {
	return c.transport.request("GET", "/1/keys/"+key, nil, read)
}

// DeleteKey deletes the API key named `key`.
func (c *Client) DeleteKey(key string) (interface{}, error) {
	return c.transport.request("DELETE", "/1/keys/"+key, nil, write)
}

// GetLogs retrieves the `length` latest logs, starting at `offset`. Logs can
// be filtered by type via `logType` being either "query", "build" or "error".
func (c *Client) GetLogs(offset, length int, logType string) (interface{}, error) {
	body := map[string]interface{}{
		"offset": offset,
		"length": length,
		"type":   logType,
	}

	return c.transport.request("GET", "/1/logs", body, write)
}

// GenerateSecuredApiKey generates a public API key intended to restrict access
// to certain records.
// This new key is built upon the existing key named `apiKey`. Tag filters
// or query parameters used to restrict access to certain records are specified
// via the `public` argument. A single `userToken` may be supplied, in order to
// use rate limited access.
func (c *Client) GenerateSecuredApiKey(apiKey string, public interface{}, userToken ...string) (string, error) {
	if len(userToken) > 1 {
		return "", errors.New("Too many parameters")
	}

	var userTokenStr string
	var message string
	if len(userToken) == 1 {
		userTokenStr = userToken[0]
	} else {
		userTokenStr = ""
	}

	if reflect.TypeOf(public).Name() != "string" { // QueryParameters
		if len(userTokenStr) != 0 {
			public.(map[string]interface{})["userToken"] = userTokenStr
		}
		message = c.transport.EncodeParams(public)
	} else if strings.Contains(public.(string), "=") { // Url encoded query parameters
		if len(userTokenStr) != 0 {
			message = public.(string) + "&" + c.transport.EncodeParams("userToken="+c.transport.urlEncode(userTokenStr))
		} else {
			message = public.(string)
		}
	} else { // TagFilters
		queryParameters := make(map[string]interface{})
		queryParameters["tagFilters"] = public
		if len(userTokenStr) != 0 {
			queryParameters["userToken"] = userTokenStr
		}
		message = c.transport.EncodeParams(queryParameters)
	}

	key := []byte(apiKey)
	h := hmac.New(sha256.New, key)
	h.Write([]byte(message))
	securedKey := hex.EncodeToString(h.Sum(nil))

	return base64.StdEncoding.EncodeToString([]byte(securedKey + message)), nil
}

// EncodeParams transforms `body` in a URL-safe string.
func (c *Client) EncodeParams(body interface{}) string {
	return c.transport.EncodeParams(body)
}

// MultipleQueries performs all the queries specified in `queries` and
// aggregates the results. It accepts two additional arguments: the name of
// the field used to store the index name in the queries, and the strategy used
// to perform the multiple queries.
// The strategy can either be "none" or "stopIfEnoughMatches".
func (c *Client) MultipleQueries(queries []interface{}, optionals ...string) (interface{}, error) {
	if len(optionals) > 2 {
		return "", errors.New("Too many parameters")
	}

	var nameKey string
	if len(optionals) >= 1 {
		nameKey = optionals[0]
	} else {
		nameKey = "indexName"
	}

	strategy := "none"
	if len(optionals) == 2 {
		strategy = optionals[1]
	}

	requests := make([]map[string]interface{}, len(queries))
	for i := range requests {
		requests[i] = map[string]interface{}{
			"indexName": queries[i].(map[string]interface{})[nameKey].(string),
		}

		delete(queries[i].(map[string]interface{}), nameKey)
		requests[i]["params"] = c.transport.EncodeParams(queries[i])
	}

	body := map[string]interface{}{
		"requests": requests,
	}

	return c.transport.request("POST", "/1/indexes/*/queries?strategy="+strategy, body, search)
}

// CustomBatch performs all queries in `queries`. Each query should contain
// the targeted index, as well as the type of operation wanted.
func (c *Client) CustomBatch(queries interface{}) (interface{}, error) {
	request := map[string]interface{}{
		"requests": queries,
	}

	return c.transport.request("POST", "/1/indexes/*/batch", request, write)
}
