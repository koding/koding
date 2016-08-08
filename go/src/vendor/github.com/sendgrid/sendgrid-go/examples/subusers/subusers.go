package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Create Subuser
// POST /subusers

func CreateSubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "email": "John@example.com", 
  "ips": [
    "1.1.1.1", 
    "2.2.2.2"
  ], 
  "password": "johns_password", 
  "username": "John@example.com"
}`)
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// List all Subusers
// GET /subusers

func ListallSubusers() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["username"] = "test_string"
  queryParams["limit"] = "1"
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

///////////////////////////////////////////////////
// Retrieve Subuser Reputations
// GET /subusers/reputations

func RetrieveSubuserReputations() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/reputations", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["usernames"] = "test_string"
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

///////////////////////////////////////////////////
// Retrieve email statistics for your subusers.
// GET /subusers/stats

func Retrieveemailstatisticsforyoursubusers() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/stats", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["end_date"] = "2016-04-01"
  queryParams["aggregated_by"] = "day"
  queryParams["limit"] = "1"
  queryParams["offset"] = "1"
  queryParams["start_date"] = "2016-01-01"
  queryParams["subusers"] = "test_string"
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

///////////////////////////////////////////////////
// Retrieve monthly stats for all subusers
// GET /subusers/stats/monthly

func Retrievemonthlystatsforallsubusers() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/stats/monthly", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["subuser"] = "test_string"
  queryParams["limit"] = "1"
  queryParams["sort_by_metric"] = "test_string"
  queryParams["offset"] = "1"
  queryParams["date"] = "test_string"
  queryParams["sort_by_direction"] = "asc"
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

///////////////////////////////////////////////////
//  Retrieve the totals for each email statistic metric for all subusers.
// GET /subusers/stats/sums

func Retrievethetotalsforeachemailstatisticmetricforallsubusers() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/stats/sums", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["end_date"] = "2016-04-01"
  queryParams["aggregated_by"] = "day"
  queryParams["limit"] = "1"
  queryParams["sort_by_metric"] = "test_string"
  queryParams["offset"] = "1"
  queryParams["start_date"] = "2016-01-01"
  queryParams["sort_by_direction"] = "asc"
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

///////////////////////////////////////////////////
// Enable/disable a subuser
// PATCH /subusers/{subuser_name}

func Enabledisableasubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "disabled": false
}`)
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Delete a subuser
// DELETE /subusers/{subuser_name}

func Deleteasubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}", host)
  request.Method = "DELETE"
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Update IPs assigned to a subuser
// PUT /subusers/{subuser_name}/ips

func UpdateIPsassignedtoasubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/ips", host)
  request.Method = "PUT"
  request.Body = []byte(` [
  "127.0.0.1"
]`)
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Update Monitor Settings for a subuser
// PUT /subusers/{subuser_name}/monitor

func UpdateMonitorSettingsforasubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
  request.Method = "PUT"
  request.Body = []byte(` {
  "email": "example@example.com", 
  "frequency": 500
}`)
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Create monitor settings
// POST /subusers/{subuser_name}/monitor

func Createmonitorsettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "email": "example@example.com", 
  "frequency": 50000
}`)
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Retrieve monitor settings for a subuser
// GET /subusers/{subuser_name}/monitor

func Retrievemonitorsettingsforasubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
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

///////////////////////////////////////////////////
// Delete monitor settings
// DELETE /subusers/{subuser_name}/monitor

func Deletemonitorsettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
  request.Method = "DELETE"
  response, err := sendgrid.API(request)
  if err != nil {
    fmt.Println(err)
  } else {
    fmt.Println(response.StatusCode)
    fmt.Println(response.Body)
    fmt.Println(response.Headers)
  }
}

///////////////////////////////////////////////////
// Retrieve the monthly email statistics for a single subuser
// GET /subusers/{subuser_name}/stats/monthly

func Retrievethemonthlyemailstatisticsforasinglesubuser() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/subusers/{subuser_name}/stats/monthly", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["date"] = "test_string"
  queryParams["sort_by_direction"] = "asc"
  queryParams["limit"] = "1"
  queryParams["sort_by_metric"] = "test_string"
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
