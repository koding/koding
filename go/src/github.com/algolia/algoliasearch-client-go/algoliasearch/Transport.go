package algoliasearch

import "net/http"
import "net/url"
import "io/ioutil"
import "bytes"
import "encoding/json"
import "strconv"
import "errors"
import "math/rand"
import "time"
import "reflect"
import "strings"

type Transport struct {
  httpClient *http.Client
  appID string
  apiKey string
  hosts [3]string
}

func NewTransport(appID, apiKey string) *Transport {
  transport := new(Transport)
  transport.appID = appID
  transport.apiKey = apiKey
  tr := &http.Transport{DisableKeepAlives: false, MaxIdleConnsPerHost: 2}
  transport.httpClient = &http.Client{Transport: tr}
  rand := rand.New(rand.NewSource(time.Now().Unix()))
  perm := rand.Perm(3)
  suffix := [3]string{"-1.algolia.io", "-2.algolia.io", "-3.algolia.io"}
  //transport.hosts = [3]string{"https://" + appID + suffix[perm[0]], "https://" + appID + suffix[perm[1]], "https://" + appID + suffix[perm[2]], }
  transport.hosts = [3]string{appID + suffix[perm[0]], appID + suffix[perm[1]], appID + suffix[perm[2]], }
  return transport
}

func (t *Transport) urlEncode(value string) string {
  return url.QueryEscape(value)
}

func (t *Transport) EncodeParams(params interface{}) string {
  v := url.Values{}
  if params != nil {
    for key, value := range params.(map[string]interface{}) {
      if reflect.TypeOf(value).Name() == "string" {
        v.Add(key, value.(string))
      } else if reflect.TypeOf(value).Name() == "float64" {
        v.Add(key, strconv.FormatFloat(value.(float64), 'f', -1, 64))
      } else {
        v.Add(key, strconv.Itoa(value.(int)))
      }
    }
  }
  return v.Encode()
}

func (t *Transport) request(method, path string, body interface{}) (interface{}, error) {
  for it := range t.hosts {
    req, err := t.buildRequest(method, t.hosts[it], path, body)
    if err != nil {
      return nil, err
    }
    req = t.addHeaders(req)
    resp, err := t.httpClient.Do(req)
    if err != nil {
      return nil, err
    }
    if resp.StatusCode == 124 ||  resp.StatusCode == 503 { //timeout or unavailable
      continue
    }
    return t.handleResponse(resp)
  }
  return nil, errors.New("Cannot reach any host.")
}

func (t *Transport) buildRequest(method, host, path string, body interface{}) (*http.Request, error) {
  var req *http.Request
  var err error
  if body != nil {
    bodyBytes, err := json.Marshal(body)
    if err != nil {
      return nil, errors.New("Invalid JSON in the query")
    }
    reader := bytes.NewReader(bodyBytes)
    req, err = http.NewRequest(method, "https://" + host + path, reader)
    req.Header.Add("Content-Length", strconv.Itoa(len(string(bodyBytes))))
    req.Header.Add("Content-Type", "application/json; charset=utf-8")
  } else {
    req, err = http.NewRequest(method, "https://" + host + path, nil)
  }
  if strings.Contains(path, "/*/") {
    req.URL = &url.URL{
       Scheme: "https",
       Host: host,
       Opaque: "//" + host + path, //Remove url encoding
     }
  }
  return req, err
}

func (t *Transport) addHeaders(req *http.Request) *http.Request {
  req.Header.Add("X-Algolia-API-Key", t.apiKey)
  req.Header.Add("X-Algolia-Application-Id", t.appID)
  req.Header.Add("Connection", "keep-alive") 
  req.Header.Add("User-Agent", "Algolia for go 1.0")
  return req
}

func (t *Transport) handleResponse(resp *http.Response) (interface{}, error) {
  res, err := ioutil.ReadAll(resp.Body)
  resp.Body.Close()
  if err != nil {
    return nil, err
  }
  var jsonResp interface{}
  err = json.Unmarshal(res, &jsonResp)
  if err != nil {
    return nil, errors.New("Invalid JSON in the response") 
  }
  if resp.StatusCode >= 200 && resp.StatusCode < 300 {
    return jsonResp, nil
  } else {
    return nil, errors.New(string(res))
  }
}
