package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve email statistics by mailbox provider.
// GET /mailbox_providers/stats

func Retrieveemailstatisticsbymailboxprovider() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/mailbox_providers/stats", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["end_date"] = "2016-04-01"
  queryParams["mailbox_providers"] = "test_string"
  queryParams["aggregated_by"] = "day"
  queryParams["limit"] = "1"
  queryParams["offset"] = "1"
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
