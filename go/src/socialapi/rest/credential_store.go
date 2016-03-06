package rest

import (
	"encoding/json"
	"fmt"
	credential "socialapi/workers/credentials/api"
)

func StoreCredentialWithAuth(pathName string, kv credential.KeyValue, token string) error {
	url := fmt.Sprintf("/credential/%s", pathName)

	_, err := marshallAndSendRequestWithAuth("POST", url, kv, token)
	return err
}

func GetCredentialWithAuth(pathName string, token string) (credential.KeyValue, error) {
	url := fmt.Sprintf("/credential/%s", pathName)

	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}
	var cr credential.KeyValue

	err = json.Unmarshal(res, &cr)
	if err != nil {
		return nil, err
	}

	return cr, nil
}

func DeleteCredentialWithAuth(pathName string, token string) error {
	url := fmt.Sprintf("/credential/%s", pathName)

	_, err := sendRequestWithAuth("DELETE", url, nil, token)
	return err
}
