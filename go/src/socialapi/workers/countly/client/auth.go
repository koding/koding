package client

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func BasicAuth(username, password, address string) string {
	client := &http.Client{}
	url := fmt.Sprintf("%v/api-key", address)
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return ""
	}
	req.SetBasicAuth(username, password)
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	bodyText, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return ""
	}

	return string(bodyText)
}
