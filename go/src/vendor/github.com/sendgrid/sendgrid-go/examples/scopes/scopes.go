package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve a list of scopes for which this user has access.
// GET /scopes

func Retrievealistofscopesforwhichthisuserhasaccess() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/scopes", host)
  request.Method = "GET"
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

func main() {
    // add your function calls here
}
