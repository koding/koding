package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

///////////////////////////////////////////////////
// Create a transactional template.
// POST /templates

func Createatransactionaltemplate() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "name": "example_name"
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
// Retrieve all transactional templates.
// GET /templates

func Retrievealltransactionaltemplates() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates", host)
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
// Edit a transactional template.
// PATCH /templates/{template_id}

func Editatransactionaltemplate() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "name": "new_example_name"
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
// Retrieve a single transactional template.
// GET /templates/{template_id}

func Retrieveasingletransactionaltemplate() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}", host)
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
// Delete a template.
// DELETE /templates/{template_id}

func Deleteatemplate() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}", host)
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
// Create a new transactional template version.
// POST /templates/{template_id}/versions

func Createanewtransactionaltemplateversion() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}/versions", host)
  request.Method = "POST"
  request.Body = []byte(` {
  "active": 1, 
  "html_content": "<%body%>", 
  "name": "example_version_name", 
  "plain_content": "<%body%>", 
  "subject": "<%subject%>", 
  "template_id": "ddb96bbc-9b92-425e-8979-99464621b543"
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
// Edit a transactional template version.
// PATCH /templates/{template_id}/versions/{version_id}

func Editatransactionaltemplateversion() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
  request.Method = "PATCH"
  request.Body = []byte(` {
  "active": 1, 
  "html_content": "<%body%>", 
  "name": "updated_example_name", 
  "plain_content": "<%body%>", 
  "subject": "<%subject%>"
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
// Retrieve a specific transactional template version.
// GET /templates/{template_id}/versions/{version_id}

func Retrieveaspecifictransactionaltemplateversion() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
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
// Delete a transactional template version.
// DELETE /templates/{template_id}/versions/{version_id}

func Deleteatransactionaltemplateversion() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
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
// Activate a transactional template version.
// POST /templates/{template_id}/versions/{version_id}/activate

func Activateatransactionaltemplateversion() {
  apiKey := os.Getenv("YOUR_SENDGRID_APIKEY")
  host := "https://api.sendgrid.com"
  request := sendgrid.GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}/activate", host)
  request.Method = "POST"
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
