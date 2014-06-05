package utils

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
)

// Gets URL and string data to be sent and makes request
// reads response body and returns as string
func DoRequest(requestType, url string, data []byte) ([]byte, error) {
	//convert string into bytestream
	var req *http.Request
	var err error

	if data == nil {
		req, err = http.NewRequest(requestType, url, nil)
	} else {
		byteData := bytes.NewReader(data)
		req, err = http.NewRequest(requestType, url, byteData)
	}

	if err != nil {
		return make([]byte, 0), err
	}

	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	// send request
	// http.Client
	client := http.Client{}
	res, err := client.Do(req)
	if err != nil {
		return make([]byte, 0), err
	}
	defer res.Body.Close()

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
