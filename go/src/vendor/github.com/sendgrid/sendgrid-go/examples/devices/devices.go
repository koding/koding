package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve email statistics by device type.
// GET /devices/stats

func Retrieveemailstatisticsbydevicetype() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/devices/stats", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["aggregated_by"] = "day"
  queryParams["limit"] = "1"
  queryParams["start_date"] = "2016-01-01"
  queryParams["end_date"] = "2016-04-01"
  queryParams["offset"] = "1"
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
