package neo4j

// this file works a helper class for other files

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
)

// do a simple json.Marshall
// returns string
func jsonEncode(value interface{}) (string, error) {
	jsonValue, err := json.Marshal(value)
	if err != nil {
		return "", err
	}
	return string(jsonValue), nil
}

// decoding json here
func jsonDecode(data string, result *interface{}) error {
	err := json.Unmarshal([]byte(data), &result)
	if err != nil {
		return err
	}

	return nil
}

// Obtain id from incoming URL
func getIDFromURL(base, url string) (string, error) {
	//add slash to end of base url,
	//because before id there is a slash
	target := base + "/"

	result := strings.SplitAfter(url, target)

	if len(result) > 1 {
		return result[1], nil
	}

	return "", errors.New("URL not valid")
}

// Gets URL and string data to be sent and makes request
// reads response body and returns as string
func (neo4j *Neo4j) doRequest(requestType, url, data string) (string, error) {
	//convert string into bytestream
	dataByte := strings.NewReader(data)
	req, err := http.NewRequest(requestType, url, dataByte)
	if err != nil {
		return "", err
	}

	// Neo4j uses json while communicating
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	if (neo4j.BasicAuthUser != "") && (neo4j.BasicAuthPassword != "") {
		req.SetBasicAuth(neo4j.BasicAuthUser, neo4j.BasicAuthPassword)
	}

	// send request
	res, err := neo4j.Client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	//todo return proper error messages with message, exception and stacktrace
	switch requestType {
	case "GET":
		// OK
		if res.StatusCode != 200 {
			return "", fmt.Errorf(res.Status)
		}
	case "POST":
		// Created
		if res.StatusCode != 201 {
			return "", fmt.Errorf(res.Status)
		}
	case "PUT", "DELETE":
		// No Content
		if res.StatusCode != 204 {
			return "", fmt.Errorf(res.Status)
		}
		return "", nil
	default:
		return "", errors.New("not supported request")
	}

	// read response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		//A successful call returns err == nil
		return "", err
	}

	return string(body), nil

}

// to-do combine this method with doRequest function
func (neo4j *Neo4j) doBatchRequest(requestType, url, data string) (string, error) {

	//convert string into bytestream
	dataByte := strings.NewReader(data)
	req, err := http.NewRequest(requestType, url, dataByte)
	if err != nil {
		return "", err
	}

	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	if (neo4j.BasicAuthUser != "") && (neo4j.BasicAuthPassword != "") {
		req.SetBasicAuth(neo4j.BasicAuthUser, neo4j.BasicAuthPassword)
	}

	res, err := neo4j.Client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()

	if res.StatusCode != 200 {
		return "", fmt.Errorf(res.Status)
	}

	// read response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		//A successful call returns err == nil
		return "", err
	}

	return string(body), nil

}
