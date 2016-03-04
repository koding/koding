package rest

import (
	"fmt"
	credential "socialapi/workers/credentials/api"
)

func StoreCredentialWithAuth(pathName string, token string) error {
	url := fmt.Sprintf("/credential/%s", pathName)
	cr := &credential.Credentials{}
	cr.KeyValue = make(map[string]interface{}, 0)
	cr.KeyValue["test-key"] = "test-value"

	_, err := marshallAndSendRequestWithAuth("POST", url, cr, token)
	return err
}

func GetCredentialWithAuth(pathName string, token string) (*credential.Credentials, error) {
	url := fmt.Sprintf("/credential/%s", pathName)
	cr := &credential.Credentials{}

	res, err := sendModelWithAuth("GET", url, cr, token)
	if err != nil {
		return nil, err
	}

	return res.(*credential.Credentials), nil
}

func DeleteCredentialWithAuth(pathName string, token string) error {
	url := fmt.Sprintf("/credential/%s", pathName)

	_, err := sendRequestWithAuth("DELETE", url, nil, token)
	return err
}
