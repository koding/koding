package main

import (
	"encoding/json"
	"fmt"
	"github.com/sendgrid/rest"
	"os"
)

func main() {

	// Build the URL
	const host = "https://api.sendgrid.com"
	endpoint := "/v3/api_keys"
	baseURL := host + endpoint

	// Build the request headers
	key := os.Getenv("SENDGRID_API_KEY")
	Headers := make(map[string]string)
	Headers["Authorization"] = "Bearer " + key

	// GET Collection
	method := rest.Get

	// Build the query parameters
	queryParams := make(map[string]string)
	queryParams["limit"] = "100"
	queryParams["offset"] = "0"

	// Make the API call
	request := rest.Request{
		Method:      method,
		BaseURL:     baseURL,
		Headers:     Headers,
		QueryParams: queryParams,
	}
	response, err := rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	// POST
	method = rest.Post

	var Body = []byte(` {
        "name": "My API Key",
        "scopes": [
            "mail.send",
            "alerts.create",
            "alerts.read"
        ]
    }`)
	request = rest.Request{
		Method:      method,
		BaseURL:     baseURL,
		Headers:     Headers,
		QueryParams: queryParams,
		Body:        Body,
	}
	response, err = rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	// Get a particular return value.
	// Note that you can unmarshall into a struct if
	// you know the JSON structure in advance.
	b := []byte(response.Body)
	var f interface{}
	err = json.Unmarshal(b, &f)
	if err != nil {
		fmt.Println(err)
	}
	m := f.(map[string]interface{})
	apiKey := m["api_key_id"].(string)

	// GET Single
	method = rest.Get

	// Make the API call
	request = rest.Request{
		Method:  method,
		BaseURL: baseURL + "/" + apiKey,
		Headers: Headers,
	}
	response, err = rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	// PATCH
	method = rest.Patch

	Body = []byte(`{
        "name": "A New Hope"
    }`)
	request = rest.Request{
		Method:  method,
		BaseURL: baseURL + "/" + apiKey,
		Headers: Headers,
		Body:    Body,
	}
	response, err = rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	// PUT
	method = rest.Put

	Body = []byte(`{
        "name": "A New Hope",
        "scopes": [
            "user.profile.read",
            "user.profile.update"
        ]
    }`)
	request = rest.Request{
		Method:  method,
		BaseURL: baseURL + "/" + apiKey,
		Headers: Headers,
		Body:    Body,
	}
	response, err = rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}

	// DELETE
	method = rest.Delete

	request = rest.Request{
		Method:      method,
		BaseURL:     baseURL + "/" + apiKey,
		Headers:     Headers,
		QueryParams: queryParams,
	}
	response, err = rest.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Headers)
	}
}
