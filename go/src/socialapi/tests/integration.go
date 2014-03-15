package main

import (
	"encoding/json"
	"fmt"
)

var (
	ENDPOINT   = "http://localhost:8000"
	ACCOUNT_ID = int64(1)
	CHANNEL_ID = int64(1)
)

func main() {
	testMessageOperations()
	testChannelOperations()
	testInteractionOperations()
	testReplyOperations()
	testHistoryOperations()
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

func marshallAndSendRequest(reqType, url string, model interface{}) ([]byte, error) {
	data, err := json.Marshal(model)
	if err != nil {
		return nil, err
	}

	return sendRequest(reqType, url, data)
}

func sendRequest(reqType, url string, data []byte) ([]byte, error) {
	url = fmt.Sprintf("%s%s", ENDPOINT, url)
	return DoRequest(reqType, url, data)
}
