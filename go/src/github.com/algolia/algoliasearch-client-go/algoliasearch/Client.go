package algoliasearch

import (
"crypto/hmac"
"crypto/sha256"
"encoding/hex"
"errors"
)

type Client struct {
  transport *Transport
}

func NewClient(appID, apiKey string) *Client {
  client := new(Client)
  client.transport = NewTransport(appID, apiKey)
  return client
}

func (c *Client) ListIndexes() (interface{}, error) {
     return c.transport.request("GET", "/1/indexes", nil)
}

func (c *Client) InitIndex(indexName string) *Index {
  return NewIndex(indexName, c)
}

func (c *Client) ListKeys() (interface{}, error) {
  return c.transport.request("GET", "/1/keys", nil)
}

func (c *Client) AddKey(acl, indexes []string, validity int, maxQueriesPerIPPerHour int, maxHitsPerQuery int) (interface{}, error) {
  body := make(map[string]interface{})
  body["acl"] = acl
  body["maxHitsPerQuery"] = maxHitsPerQuery
  body["maxQueriesPerIPPerHour"] = maxQueriesPerIPPerHour
  body["validity"] = validity
  body["indexes"] = indexes
  return c.transport.request("POST", "/1/keys/", body)
}

func (c *Client) GetKey(key string) (interface{}, error) {
  return c.transport.request("GET", "/1/keys/" + key, nil)
}

func (c *Client) DeleteKey(key string) (interface{}, error) {
  return c.transport.request("DELETE", "/1/keys/" + key, nil)
}

func (c *Client) GetLogs(offset, length int, onlyErrors bool) (interface{}, error) {
  body := make(map[string]interface{})
  body["offset"] = offset
  body["length"] = length
  body["onlyErrors"] = onlyErrors
  return c.transport.request("GET", "/1/logs", body)
}

func (c *Client) GenerateSecuredApiKey(apiKey string, tagFilters string, userToken ...string) (string, error) {
  if len(userToken) > 1 {
    return "", errors.New("Too many parameters")
  }
  key := []byte(apiKey)
  h := hmac.New(sha256.New, key)
  var userTokenStr string
  if len(userToken) == 1 {
    userTokenStr = userToken[0]
  } else {
    userTokenStr = ""
  }
  message := tagFilters + userTokenStr
  h.Write([]byte(message))
  return hex.EncodeToString(h.Sum(nil)), nil
}

func (c *Client) MultipleQueries(queries []interface{}, indexNameKey ...string) (interface{}, error) {
  if len(indexNameKey) > 1 {
    return "", errors.New("Too many parametters")
  }
  var nameKey string
  if len(indexNameKey) == 1 {
    nameKey = indexNameKey[0]
  } else {
    nameKey = "indexName"
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
  return c.transport.request("POST", "/1/indexes/*/queries", body)
}
