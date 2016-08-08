// Package sendgrid provides a simple interface to interact with the SendGrid API
package sendgrid

import "github.com/sendgrid/rest" // depends on version 2.0.0

const Version = "3.0.0"

// GetRequest returns a default request object.
func GetRequest(key string, endpoint string, host string) rest.Request {
	if host == "" {
		host = "https://api.sendgrid.com"
	}
	baseURL := host + endpoint
	requestHeaders := make(map[string]string)
	requestHeaders["Authorization"] = "Bearer " + key
	requestHeaders["User-Agent"] = "sendgrid/" + Version + ";go"
	requestHeaders["Accept"] = "application/json"
	request := rest.Request{
		BaseURL: baseURL,
		Headers: requestHeaders,
	}
	return request
}

// API sets up the request to the SendGrid API, this is main interface.
func API(request rest.Request) (*rest.Response, error) {
	response, err := rest.API(request)
	if err != nil {
		return nil, err
	}
	return response, nil
}
