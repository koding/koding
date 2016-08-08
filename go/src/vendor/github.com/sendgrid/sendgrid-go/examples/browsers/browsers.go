package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve email statistics by browser. 
// GET /browsers/stats

func Retrieveemailstatisticsbybrowser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/browsers/stats", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["end_date"] = "2016-04-01"
  queryParams["aggregated_by"] = "day"
  queryParams["browsers"] = "test_string"
  queryParams["limit"] = "test_string"
  queryParams["offset"] = "test_string"
  queryParams["start_date"] = "2016-01-01"
  request.QueryParams = queryParams
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
