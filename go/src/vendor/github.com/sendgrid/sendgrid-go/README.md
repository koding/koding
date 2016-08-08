[![Build Status](https://travis-ci.org/sendgrid/sendgrid-go.svg?branch=master)](https://travis-ci.org/sendgrid/sendgrid-go)

**This library allows you to quickly and easily use the SendGrid Web API v3 via Go.**

Version 3.X.X of this library provides full support for all SendGrid [Web API v3](https://sendgrid.com/docs/API_Reference/Web_API_v3/index.html) endpoints, including the new [v3 /mail/send](https://sendgrid.com/blog/introducing-v3mailsend-sendgrids-new-mail-endpoint).

This library represents the beginning of a new path for SendGrid. We want this library to be community driven and SendGrid led. We need your help to realize this goal. To help make sure we are building the right things in the right order, we ask that you create [issues](https://github.com/sendgrid/sendgrid-go/issues) and [pull requests](https://github.com/sendgrid/sendgrid-go/blob/master/CONTRIBUTING.md) or simply upvote or comment on existing issues or pull requests.

Please browse the rest of this README for further detail.

We appreciate your continued support, thank you!

# Installation

## Prerequisites

- Go version 1.6
- The SendGrid service, starting at the [free level](https://sendgrid.com/free?source=sendgrid-go)

## Setup Environment Variables

Update the development environment with your [SENDGRID_API_KEY](https://app.sendgrid.com/settings/api_keys), for example:

```bash
echo "export SENDGRID_API_KEY='YOUR_API_KEY'" > sendgrid.env
echo "sendgrid.env" >> .gitignore
source ./sendgrid.env
```

## Install Package

`go get github.com/sendgrid/sendgrid-go`

```go
import "github.com/sendgrid/sendgrid-go"
```

## Dependencies

- [rest](https://github.com/sendgrid/rest)

# Quick Start

## Hello Email

The following is the minimum needed code to send an email with the [/mail/send Helper](https://github.com/sendgrid/sendgrid-go/tree/master/helpers/mail) ([here](https://github.com/sendgrid/sendgrid-go/blob/master/examples/helpers/mail/example.go#L32) is a full example):

### With Mail Helper Class

```go
package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
	"os"
)

func main() {
	from := mail.NewEmail("Example User", "test@example.com")
	subject := "Hello World from the SendGrid Go Library"
	to := mail.NewEmail("Example User", "test@example.com")
	content := mail.NewContent("text/plain", "some text here")
	m := mail.NewV3MailInit(from, subject, to, content)

	request := sendgrid.GetRequest(os.Getenv("SENDGRID_API_KEY"), "/v3/mail/send", "https://api.sendgrid.com")
	request.Method = "POST"
	request.Body = mail.GetRequestBody(m)
	response, err := sendgrid.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}
}
```

The `NewV3MailInit` constructor creates a [personalization object](https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html) for you. [Here](https://github.com/sendgrid/sendgrid-go/blob/master/examples/helpers/mail/example.go#L28) is an example of how to add to it.

### Without Mail Helper Class

The following is the minimum needed code to send an email without the /mail/send Helper ([here](https://github.com/sendgrid/sendgrid-go/blob/master/examples/mail/mail.go#L47) is a full example):

```go
package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

func main() {
	request := sendgrid.GetRequest(os.Getenv("SENDGRID_API_KEY"), "/v3/mail/send", "https://api.sendgrid.com")
	request.Method = "POST"
	request.Body = []byte(` {
	"personalizations": [
		{
			"to": [
				{
					"email": "test@example.com"
				}
			],
			"subject": "Hello World from the SendGrid Go Library!"
		}
	],
	"from": {
		"email": "test@example.com"
	},
	"content": [
		{
			"type": "text/plain",
			"value": "Hello, Email!"
		}
	]
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
```

## General v3 Web API Usage

```go
package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"os"
)

func main() {
	request := sendgrid.GetRequest(os.Getenv("SENDGRID_API_KEY"), "/v3/api_keys", "https://api.sendgrid.com")
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
```

# Usage

- [SendGrid Docs](https://sendgrid.com/docs/API_Reference/index.html)
- [Library Usage Docs](https://github.com/sendgrid/sendgrid-go/tree/master/USAGE.md)
- [Example Code](https://github.com/sendgrid/sendgrid-go/tree/master/examples)
- [How-to: Migration from v2 to v3](https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/how_to_migrate_from_v2_to_v3_mail_send.html)
- [v3 Web API Mail Send Helper](https://github.com/sendgrid/sendgrid-go/tree/master/helpers/mail/README.md)

# Announcements

All updates to this library is documented in our [CHANGELOG](https://github.com/sendgrid/sendgrid-go/blob/master/CHANGELOG.md) and [releases](https://github.com/sendgrid/sendgrid-go/releases).

# Roadmap

If you are interested in the future direction of this project, please take a look at our open [issues](https://github.com/sendgrid/sendgrid-go/issues) and [pull requests](https://github.com/sendgrid/sendgrid-go/pulls). We would love to hear your feedback.

# How to Contribute

We encourage contribution to our libraries (you might even score some nifty swag), please see our [CONTRIBUTING](https://github.com/sendgrid/sendgrid-go/blob/master/CONTRIBUTING.md) guide for details.

Quick links:

- [Feature Request](https://github.com/sendgrid/sendgrid-go/tree/master/CONTRIBUTING.md#feature_request)
- [Bug Reports](https://github.com/sendgrid/sendgrid-go/tree/master/CONTRIBUTING.md#submit_a_bug_report)
- [Sign the CLA to Create a Pull Request](https://github.com/sendgrid/sendgrid-go/tree/master/CONTRIBUTING.md#cla)
- [Improvements to the Codebase](https://github.com/sendgrid/sendgrid-go/tree/master/CONTRIBUTING.md#improvements_to_the_codebase)

# About

sendgrid-go is guided and supported by the SendGrid [Developer Experience Team](mailto:dx@sendgrid.com).

sendgrid-go is maintained and funded by SendGrid, Inc. The names and logos for sendgrid-go are trademarks of SendGrid, Inc.

![SendGrid Logo]
(https://uiux.s3.amazonaws.com/2016-logos/email-logo%402x.png)
