package algoliasearch

import (
	"net"
	"net/http"
)
import "net/url"
import "io/ioutil"
import "bytes"
import "encoding/json"
import "strconv"
import "errors"
import "time"
import "reflect"
import "strings"
import "fmt"

// Fix certificates
import _ "crypto/sha512"

const (
	version = "1.4.0"
)

const (
	search = 1 << iota
	write
	read
)

type Transport struct {
	httpClient    *http.Client
	appID         string
	apiKey        string
	headers       map[string]string
	hosts         []string
	hostsProvided bool
}

func NewTransport(appID, apiKey string) *Transport {
	transport := new(Transport)
	transport.appID = appID
	transport.apiKey = apiKey
	tr := &http.Transport{
		DisableKeepAlives:   false,
		MaxIdleConnsPerHost: 2,
		Dial: (&net.Dialer{
			Timeout:   15 * time.Second,
			KeepAlive: 30 * time.Second,
		}).Dial,
		TLSHandshakeTimeout:   time.Second * 2,
		ResponseHeaderTimeout: time.Second * 10}

	transport.httpClient = &http.Client{Transport: tr, Timeout: time.Second * 15}
	transport.headers = make(map[string]string)
	transport.hosts = make([]string, 3)
	transport.hosts[0] = appID + "-1.algolianet.com"
	transport.hosts[1] = appID + "-2.algolianet.com"
	transport.hosts[2] = appID + "-3.algolianet.com"
	transport.hostsProvided = false
	return transport
}

func NewTransportWithHosts(appID, apiKey string, hosts []string) *Transport {
	transport := new(Transport)
	transport.appID = appID
	transport.apiKey = apiKey
	tr := &http.Transport{
		DisableKeepAlives:   false,
		MaxIdleConnsPerHost: 2,
		Dial: (&net.Dialer{
			Timeout:   15 * time.Second,
			KeepAlive: 30 * time.Second,
		}).Dial,
		TLSHandshakeTimeout:   time.Second * 2,
		ResponseHeaderTimeout: time.Second * 10}

	transport.httpClient = &http.Client{Transport: tr, Timeout: time.Second * 15}
	transport.headers = make(map[string]string)
	transport.hosts = hosts
	transport.hostsProvided = true
	return transport
}

func (t *Transport) setTimeout(connectTimeout time.Duration, readTimeout time.Duration) {
	t.httpClient.Transport.(*http.Transport).TLSHandshakeTimeout = connectTimeout
	t.httpClient.Transport.(*http.Transport).ResponseHeaderTimeout = readTimeout
}

func (t *Transport) urlEncode(value string) string {
	return url.QueryEscape(value)
}

func (t *Transport) setExtraHeader(key string, value string) {
	t.headers[key] = value
}

func (t *Transport) EncodeParams(params interface{}) string {
	v := url.Values{}
	if params != nil {
		for key, value := range params.(map[string]interface{}) {
			if reflect.TypeOf(value).Name() == "string" {
				v.Add(key, value.(string))
			} else if reflect.TypeOf(value).Name() == "float64" {
				v.Add(key, strconv.FormatFloat(value.(float64), 'f', -1, 64))
			} else if reflect.TypeOf(value).Name() == "int" {
				v.Add(key, strconv.Itoa(value.(int)))
			} else {
				jsonValue, _ := json.Marshal(value)
				v.Add(key, string(jsonValue[:]))
			}
		}
	}
	return v.Encode()
}

func (t *Transport) request(method, path string, body interface{}, typeCall int) (interface{}, error) {
	var host string
	errorMsg := ""
	if typeCall == write {
		host = t.appID + ".algolia.net"
	} else {
		host = t.appID + "-dsn.algolia.net"
	}

	if !t.hostsProvided {
		req, err := t.buildRequest(method, host, path, body)
		if err != nil {
			return nil, err
		}
		req = t.addHeaders(req)
		resp, err := t.httpClient.Do(req)
		if err != nil {
			if len(errorMsg) > 0 {
				errorMsg = fmt.Sprintf("%s, %s:%s", errorMsg, host, err)
			} else {
				errorMsg = fmt.Sprintf("%s:%s", host, err)
			}
		} else if (resp.StatusCode/100) == 2 || (resp.StatusCode/100) == 4 { // Bad request, not found, forbidden
			return t.handleResponse(resp)
		} else {
			resp.Body.Close()
		}
	}

	for it := range t.hosts {
		req, err := t.buildRequest(method, t.hosts[it], path, body)
		if err != nil {
			return nil, err
		}
		req = t.addHeaders(req)
		resp, err := t.httpClient.Do(req)
		if err != nil {
			if len(errorMsg) > 0 {
				errorMsg = fmt.Sprintf("%s, %s:%s", errorMsg, t.hosts[it], err)
			} else {
				errorMsg = fmt.Sprintf("%s:%s", t.hosts[it], err)
			}
			continue
		}
		if (resp.StatusCode/100) == 2 || (resp.StatusCode/100) == 4 { // Bad request, not found, forbidden
			return t.handleResponse(resp)
		} else {
			resp.Body.Close()
		}
	}
	return nil, errors.New(fmt.Sprintf("Cannot reach any host. (%s)", errorMsg))
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
		req, err = http.NewRequest(method, "https://"+host+path, reader)
		req.Header.Add("Content-Length", strconv.Itoa(len(string(bodyBytes))))
		req.Header.Add("Content-Type", "application/json; charset=utf-8")
	} else {
		req, err = http.NewRequest(method, "https://"+host+path, nil)
	}
	if strings.Contains(path, "/*/") {
		req.URL = &url.URL{
			Scheme: "https",
			Host:   host,
			Opaque: "//" + host + path, //Remove url encoding
		}
	}
	return req, err
}

func (t *Transport) addHeaders(req *http.Request) *http.Request {
	req.Header.Add("X-Algolia-API-Key", t.apiKey)
	req.Header.Add("X-Algolia-Application-Id", t.appID)
	req.Header.Add("Connection", "keep-alive")
	req.Header.Add("User-Agent", "Algolia for go "+version)
	for key := range t.headers {
		req.Header.Add(key, t.headers[key])
	}
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
