package algoliasearch

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"reflect"
	"time"
	"strings"
	"encoding/base64"
)

type Client struct {
	transport *Transport
}

func NewClient(appID, apiKey string) *Client {
	client := new(Client)
	client.transport = NewTransport(appID, apiKey)
	return client
}

func NewClientWithHosts(appID, apiKey string, hosts []string) *Client {
	client := new(Client)
	client.transport = NewTransportWithHosts(appID, apiKey, hosts)
	return client
}

func (c *Client) SetExtraHeader(key string, value string) {
	c.transport.setExtraHeader(key, value)
}

func (c *Client) SetTimeout(connectTimeout int, readTimeout int) {
	c.transport.setTimeout(time.Duration(connectTimeout)*time.Millisecond, time.Duration(readTimeout)*time.Millisecond)
}

func (c *Client) ListIndexes() (interface{}, error) {
	return c.transport.request("GET", "/1/indexes", nil, read)
}

func (c *Client) InitIndex(indexName string) *Index {
	return NewIndex(indexName, c)
}

func (c *Client) ListKeys() (interface{}, error) {
	return c.transport.request("GET", "/1/keys", nil, read)
}

func (c *Client) MoveIndex(source string, destination string) (interface{}, error) {
	return c.InitIndex(source).Move(destination)
}

func (c *Client) CopyIndex(source string, destination string) (interface{}, error) {
	return c.InitIndex(source).Copy(destination)
}

func (c *Client) AddKey(acl, indexes []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := make(map[string]interface{})
	body["acl"] = acl
	body["maxHitsPerQuery"] = maxHitsPerQuery
	body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
	body["validity"] = validity
	body["indexes"] = indexes
	return c.AddKeyWithParam(body)
}

func (c *Client) AddKeyWithParam(params interface{}) (interface{}, error) {
	return c.transport.request("POST", "/1/keys/", params, read)
}

func (c *Client) UpdateKey(key string, acl, indexes []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
	body := make(map[string]interface{})
	body["acl"] = acl
	body["maxHitsPerQuery"] = maxHitsPerQuery
	body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
	body["validity"] = validity
	body["indexes"] = indexes
	return c.UpdateKeyWithParam(key, body)
}

func (c *Client) UpdateKeyWithParam(key string, params interface{}) (interface{}, error) {
	return c.transport.request("PUT", "/1/keys/"+key, params, write)
}

func (c *Client) GetKey(key string) (interface{}, error) {
	return c.transport.request("GET", "/1/keys/"+key, nil, read)
}

func (c *Client) DeleteKey(key string) (interface{}, error) {
	return c.transport.request("DELETE", "/1/keys/"+key, nil, write)
}

func (c *Client) GetLogs(offset, length int, logType string) (interface{}, error) {
	body := make(map[string]interface{})
	body["offset"] = offset
	body["length"] = length
	body["type"] = logType
	return c.transport.request("GET", "/1/logs", body, write)
}

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
		if (len(userTokenStr) != 0) {
			message = public.(string) + "&" + c.transport.EncodeParams("userToken=" + c.transport.urlEncode(userTokenStr))
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

func (c *Client) EncodeParams(body interface{}) string {
	return c.transport.EncodeParams(body)
}

func (c *Client) MultipleQueries(queries []interface{}, optionals ...string) (interface{}, error) {
	if len(optionals) > 2 {
		return "", errors.New("Too many parametters")
	}
	var nameKey string
	if len(optionals) >= 1 {
		nameKey = optionals[0]
	} else {
		nameKey = "indexName"
	}
	var strategy string = "none"
	if len(optionals) == 2 {
		strategy = optionals[1]
	}
	requests := make([]map[string]interface{}, len(queries))
	for i := range queries {
		requests[i] = make(map[string]interface{})
		requests[i]["indexName"] = queries[i].(map[string]interface{})[nameKey].(string)
		delete(queries[i].(map[string]interface{}), nameKey)
		requests[i]["params"] = c.transport.EncodeParams(queries[i])
	}
	body := make(map[string]interface{})
	body["requests"] = requests
	return c.transport.request("POST", "/1/indexes/*/queries?strategy="+strategy, body, search)
}

func (c *Client) CustomBatch(queries interface{}) (interface{}, error) {
	request := make(map[string]interface{})
	request["requests"] = queries
	return c.transport.request("POST", "/1/indexes/*/batch", request, write)
}
