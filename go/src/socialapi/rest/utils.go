package rest

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"
)

var (
	ENDPOINT = "http://localhost:7000"
)

func init() {
	env := os.Getenv("SOCIALAPI_HOSTNAME")
	if env != "" {
		ENDPOINT = env
	}
}

func createHttpReq(requestType, url string, data []byte) (*http.Request, error) {
	var req *http.Request
	var err error

	if data == nil {
		req, err = http.NewRequest(requestType, url, nil)
	} else {
		byteData := bytes.NewReader(data)
		req, err = http.NewRequest(requestType, url, byteData)
	}

	if err != nil {
		return nil, err
	}

	return req, nil
}

// Gets URL and string data to be sent and makes request
// reads response body and returns as string
func DoRequest(requestType, url string, data []byte) ([]byte, error) {
	req, err := createHttpReq(requestType, url, data)
	if err != nil {
		return make([]byte, 0), err
	}

	return DoWithRequest(req, requestType, url, data)
}

func DoRequestWithAuth(requestType, url string, data []byte, token string) ([]byte, error) {
	req, err := createHttpReq(requestType, url, data)
	if err != nil {
		return make([]byte, 0), err
	}

	expire := time.Now().AddDate(0, 0, 1)
	cookie := http.Cookie{
		Name:       "clientId",
		Value:      token,
		Path:       "/",
		Domain:     "localhost",
		Expires:    expire,
		RawExpires: expire.Format(time.UnixDate),
		Raw:        "clientId=" + token,
		Unparsed:   []string{"test=" + token},
	}

	req.AddCookie(&cookie)

	return DoWithRequest(req, requestType, url, data)
}

// Gets URL and string data to be sent and makes request
// reads response body and returns as string
func DoWithRequest(req *http.Request, requestType, url string, data []byte) ([]byte, error) {
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	// send request
	// http.Client
	client := http.Client{}
	res, err := client.Do(req)
	defer func() {
		if res != nil {
			res.Body.Close()
		}
	}()

	if err != nil {
		return make([]byte, 0), err
	}

	return MapHTTPResponse(res)

}

func MapHTTPResponse(res *http.Response) ([]byte, error) {
	r := make(map[string]interface{}, 0)

	body, err := readBody(res.Body)
	if err != nil {
		return nil, err
	}

	if res.StatusCode >= 200 && res.StatusCode <= 205 {
		return body, nil
	}

	err = json.Unmarshal(body, &r)
	if err != nil {
		return make([]byte, 0), err
	}
	return nil, errors.New(fmt.Sprintf("%s-%s", r["error"].(string), r["description"].(string)))
}

func readBody(body io.Reader) ([]byte, error) {
	b, err := ioutil.ReadAll(body)
	return b, err
}

type Response struct {
	Data  json.RawMessage `json:"data"`
	Error string          `json:"error"`
}

func sendModel(reqType, url string, model interface{}) (interface{}, error) {

	res, err := marshallAndSendRequest(reqType, url, model)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model, nil
}

func sendModelWithAuth(reqType, url string, model interface{}, token string) (interface{}, error) {
	res, err := marshallAndSendRequestWithAuth(reqType, url, model, token)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model, nil
}

func marshallAndSendRequest(reqType, url string, model interface{}) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return sendRequest(reqType, url, data)
}

func marshallAndSendRequestWithHeader(reqType, url string, model interface{}, h http.Header) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return sendRequestWithHeader(reqType, url, data, h)
}

func marshallAndSendRequestWithHeaderAndAuth(reqType, url string, model interface{}, h http.Header, token string) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return sendRequestWithHeaderAndAuth(reqType, url, data, h, token)
}

func marshallAndSendRequestWithAuth(reqType, url string, model interface{}, token string) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return sendRequestWithAuth(reqType, url, data, token)
}

func sendRequest(reqType, url string, data []byte) ([]byte, error) {
	url = prepareURL(url)
	return DoRequest(reqType, url, data)
}

func sendRequestWithHeader(reqType, url string, data []byte, h http.Header) ([]byte, error) {
	url = prepareURL(url)
	req, err := createHttpReq(reqType, url, data)
	if err != nil {
		return nil, err
	}
	req.Header = h

	return DoWithRequest(req, reqType, url, data)
}

func sendRequestWithAuth(reqType, url string, data []byte, token string) ([]byte, error) {
	url = prepareURL(url)
	return DoRequestWithAuth(reqType, url, data, token)
}

func sendRequestWithHeaderAndAuth(reqType, url string, data []byte, h http.Header, token string) ([]byte, error) {
	url = prepareURL(url)
	req, err := createHttpReq(reqType, url, data)
	if err != nil {
		return nil, err
	}
	req.Header = h

	return DoRequestWithAuth(reqType, url, data, token)
}

func prepareURL(url string) string {
	if strings.Contains(url, "http") {
		return url
	}

	return fmt.Sprintf("%s%s", ENDPOINT, url)
}
