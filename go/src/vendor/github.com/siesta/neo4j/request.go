package neo4j

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
)

// ManuelRequest struct for create a custom Neo4J request
// This is particularly used for creating Batch opeartion requests
type ManuelRequest struct {
	To     string
	Params map[string]string
	Body   map[string]string
}

// Get func
func (mr *ManuelRequest) Get() ([]string, error) {
	urlWithParams := mr.encodeParams()
	req, err := http.NewRequest("GET", urlWithParams, nil)
	if err != nil {
		return nil, err
	}

	resp, err := mr.getDeleteHelper(req)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

// Delete func
func (mr *ManuelRequest) Delete() error {
	urlWithParams := mr.encodeParams()
	req, err := http.NewRequest("DELETE", urlWithParams, nil)
	if err != nil {
		return err
	}

	_, err = mr.getDeleteHelper(req)
	if err != nil {
		return err
	}

	return nil
}

func (mr *ManuelRequest) getDeleteHelper(req *http.Request) ([]string, error) {
	client := &http.Client{}
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	resp, err := mr.decodeResponse(res)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

// Post func
func (mr *ManuelRequest) Post() error {
	body, err := jsonEncode(mr.Body)
	if err != nil {
		return err
	}

	jsonBody := strings.NewReader(body)
	req, err := http.NewRequest("POST", mr.To, jsonBody)
	if err != nil {
		return err
	}

	mr.encodeForm(req)
	client := &http.Client{}
	res, err := client.PostForm(mr.To, req.Form)
	if err != nil {
		return err
	}

	_, err = mr.decodeResponse(res)
	if err != nil {
		return err
	}

	defer res.Body.Close()

	return nil
}

func (mr *ManuelRequest) decodeResponse(res *http.Response) ([]string, error) {
	switch res.StatusCode {
	case 200, 500:
		body, err := ioutil.ReadAll(res.Body)
		if err != nil {
			return nil, err
		}

		var result = make([]string, 0)
		err = json.Unmarshal(body, &result)
		if err != nil {
			return nil, err
		}

		return result, nil
	case 204:
	default:
		return nil, fmt.Errorf(res.Status)
	}

	return nil, nil
}

func (mr *ManuelRequest) encodeParams() string {
	var urlWithParams string

	if mr.Params != nil {
		params := url.Values{}
		for key, value := range mr.Params {
			params.Add(key, value)
		}

		urlWithParams = fmt.Sprintf("%s?%s", mr.To, params.Encode())
	} else {
		urlWithParams = mr.To
	}

	return urlWithParams
}

func (mr *ManuelRequest) encodeForm(req *http.Request) {
	if mr.Body != nil {
		req.Form = url.Values{}

		for k, v := range mr.Body {
			req.Form.Add(k, v)
		}
	}
}
