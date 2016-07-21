package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve all IP addresses
// GET /ips

func RetrieveallIPaddresses() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
  queryParams["subuser"] = "test_string"
  queryParams["ip"] = "test_string"
  queryParams["limit"] = "1"
  queryParams["exclude_whitelabels"] = "true"
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
// Retrieve all assigned IPs
// GET /ips/assigned

func RetrieveallassignedIPs() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/assigned", host)
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
// Create an IP pool.
// POST /ips/pools

func CreateanIPpool() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "name": "marketing"
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
// Retrieve all IP pools.
// GET /ips/pools

func RetrieveallIPpools() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools", host)
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
// Update an IP pools name.
// PUT /ips/pools/{pool_name}

func UpdateanIPpoolsname() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
  request.Method = "PUT"
  request.Body = []byte(` {
  "name": "new_pool_name"
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
// Retrieve all IPs in a specified pool.
// GET /ips/pools/{pool_name}

func RetrieveallIPsinaspecifiedpool() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
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
// Delete an IP pool.
// DELETE /ips/pools/{pool_name}

func DeleteanIPpool() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
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
// Add an IP address to a pool
// POST /ips/pools/{pool_name}/ips

func AddanIPaddresstoapool() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools/{pool_name}/ips", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "ip": "0.0.0.0"
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
// Remove an IP address from a pool.
// DELETE /ips/pools/{pool_name}/ips/{ip}

func RemoveanIPaddressfromapool() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/pools/{pool_name}/ips/{ip}", host)
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
// Add an IP to warmup
// POST /ips/warmup

func AddanIPtowarmup() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/warmup", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "ip": "0.0.0.0"
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
// Retrieve all IPs currently in warmup
// GET /ips/warmup

func RetrieveallIPscurrentlyinwarmup() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/warmup", host)
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
// Retrieve warmup status for a specific IP address
// GET /ips/warmup/{ip_address}

func RetrievewarmupstatusforaspecificIPaddress() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/warmup/{ip_address}", host)
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
// Remove an IP from warmup
// DELETE /ips/warmup/{ip_address}

func RemoveanIPfromwarmup() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/warmup/{ip_address}", host)
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
// Retrieve all IP pools an IP address belongs to
// GET /ips/{ip_address}

func RetrieveallIPpoolsanIPaddressbelongsto() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/ips/{ip_address}", host)
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
