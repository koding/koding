package utils

import (
	"encoding/json"
	"fmt"
)

var (
	// TODO this must be injected
	ENDPOINT = "http://localhost:7000"
)

func SendModel(reqType, url string, model interface{}) (interface{}, error) {

	res, err := MarshallAndSendRequest(reqType, url, model)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(res, model)
	if err != nil {
		return nil, err
	}

	return model, nil
}

func MarshallAndSendRequest(reqType, url string, model interface{}) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return SendRequest(reqType, url, data)
}

func SendRequest(reqType, url string, data []byte) ([]byte, error) {
	url = fmt.Sprintf("%s%s", ENDPOINT, url)
	return DoRequest(reqType, url, data)
}
