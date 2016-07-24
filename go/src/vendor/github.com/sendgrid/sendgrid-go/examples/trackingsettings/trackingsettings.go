package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Retrieve Tracking Settings
// GET /tracking_settings

func RetrieveTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings", host)
  request.Method = "GET"
  queryParams := make(map[string]string)
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
// Update Click Tracking Settings
// PATCH /tracking_settings/click

func UpdateClickTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/click", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "enabled": true
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
// Retrieve Click Track Settings
// GET /tracking_settings/click

func RetrieveClickTrackSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/click", host)
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
// Update Google Analytics Settings
// PATCH /tracking_settings/google_analytics

func UpdateGoogleAnalyticsSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/google_analytics", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "enabled": true, 
  "utm_campaign": "website", 
  "utm_content": "", 
  "utm_medium": "email", 
  "utm_source": "sendgrid.com", 
  "utm_term": ""
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
// Retrieve Google Analytics Settings
// GET /tracking_settings/google_analytics

func RetrieveGoogleAnalyticsSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/google_analytics", host)
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
// Update Open Tracking Settings
// PATCH /tracking_settings/open

func UpdateOpenTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/open", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "enabled": true
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
// Get Open Tracking Settings
// GET /tracking_settings/open

func GetOpenTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/open", host)
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
// Update Subscription Tracking Settings
// PATCH /tracking_settings/subscription

func UpdateSubscriptionTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/subscription", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "enabled": true, 
  "html_content": "html content", 
  "landing": "landing page html", 
  "plain_content": "text content", 
  "replace": "replacement tag", 
  "url": "url"
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
// Retrieve Subscription Tracking Settings
// GET /tracking_settings/subscription

func RetrieveSubscriptionTrackingSettings() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/tracking_settings/subscription", host)
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
