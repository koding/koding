# SendGrid-Go
[![Build Status](https://travis-ci.org/sendgrid/sendgrid-go.svg?branch=master)](https://travis-ci.org/sendgrid/sendgrid-go)
SendGrid Helper Library to send emails very easily using Go.

## Installation

```bash
go get github.com/sendgrid/sendgrid-go
```

## Example

```go
package main

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
)

func main() {
	sg := sendgrid.NewSendGridClient("sendgrid_user", "sendgrid_key")
	message := sendgrid.NewMail()
	message.AddTo("yamil@sendgrid.com")
	message.AddToName("Yamil Asusta")
	message.SetSubject("SendGrid Testing")
	message.SetText("WIN")
	message.SetFrom("yamil@sendgrid.com")
    if r := sg.Send(message); r == nil {
		fmt.Println("Email sent!")
	} else {
		fmt.Println(r)
	}
}

```

### Creating a Client

```go
sg := sendgrid.NewSendGridClient("sendgrid_user", "sendgrid_key")
```

### Creating a Mail
```go
message := sendgrid.NewMail()
```

### Adding Recipients

```go
message.AddTo("example@sendgrid.com") // Returns error if email string is not valid RFC 5322
// or
address, _ := mail.ParseAddress("Example <example@sendgrid.com>")
message.AddRecipient(address) // Receives a vaild mail.Address
```

### Adding BCC Recipients

Same concept as regular recipient excepts the methods are:

*   AddBCC
*   AddRecipientBCC

### Setting the Subject

```go
message.SetSubject("New email")
```

### Set Text or HTML

```go
message.SetText("Add Text Here..")
//or
message.SetHTML("<html><body>Stuff, you know?</body></html>")
```
### Set From

```go
message.SetFrom("example@lol.com")
```
### Set File Attachments

```go
message.AddAttachment("text.txt", file) // file needs to implement the io.Reader interface
//or
message.AddAttachmentStream("filename", []byte("some file content"))
```
### Adding ContentIDs

```go
message.AddContentID("id", "content")
```

## SendGrid's  [X-SMTPAPI](http://sendgrid.com/docs/API_Reference/SMTP_API/)

If you wish to use the X-SMTPAPI on your own app, you can use the [SMTPAPI Go library](https://github.com/sendgrid/smtpapi-go).


### Recipients

```go
message.AddTo("addTo@mailinator.com")
// or
tos := []string{"test@test.com", "test@email.com"}
message.AddTos(tos)
// or
message.SetTos(tos)
```

### [Substitutions](http://sendgrid.com/docs/API_Reference/SMTP_API/substitution_tags.html)

```go
message.AddSubstitution("key", "value")
// or
values := []string{"value1", "value2"}
message.AddSubstitutions("key", values)
//or
sub := make(map[string][]string)
sub["key"] = values
message.SetSubstitutions(sub)
```

### [Section](http://sendgrid.com/docs/API_Reference/SMTP_API/section_tags.html)

```go
message.AddSection("section", "value")
// or
sections := make(map[string]string)
sections["section"] = "value"
message.SetSections(sections)
```

### [Category](http://sendgrid.com/docs/Delivery_Metrics/categories.html)

```go
message.AddCategory("category")
// or
categories := []string{"setCategories"}
message.AddCategories(categories)
// or
message.SetCategories(categories)
```

### [Unique Arguments](http://sendgrid.com/docs/API_Reference/SMTP_API/unique_arguments.html)

```go
message.AddUniqueArg("key", "value")
// or
args := make(map[string]string)
args["key"] = "value"
message.SetUniqueArgs(args)
```

### [Filters](http://sendgrid.com/docs/API_Reference/SMTP_API/apps.html)

```go
message.AddFilter("filter", "setting", "value")
// or
filter := &Filter{
  Settings: make(map[string]string),
}
filter.Settings["enable"] = "1"
filter.Settings["text/plain"] = "You can haz footers!"
message.SetFilter("footer", filter)
```

### JSONString

```go
message.JSONString() //returns a JSON string representation of the headers
```

## AppEngine Example

```go
package main

import (
	"fmt"
	"appengine/urlfetch"
	"github.com/sendgrid/sendgrid-go"
)

func handler(w http.ResponseWriter, r *http.Request) {
	sg := sendgrid.NewSendGridClient("sendgrid_user", "sendgrid_key")
	c := appengine.NewContext(r)
	// set http.Client to use the appengine client
	sg.Client = urlfetch.Client(c) //Just perform this swap, and you are good to go.
	message := sendgrid.NewMail()
	message.AddTo("yamil@sendgrid.com")
	message.SetSubject("SendGrid is Baller")
	message.SetHTML("Simple Text")
	message.SetFrom("kunal@sendgrid.com")
	if r := sg.Send(message); r == nil {
		fmt.Println("Email sent!")
	} else {
		c.Errorf("Unable to send mail %v",r)
	}
}

```

Kudos to [Matthew Zimmerman](https://github.com/mzimmerman) for this example.

###Tests

Please run the test suite in before sending a pull request.

```bash
go test -v
```

### TODO:
* Add Versioning
* Add proper support for BCC

##MIT License

Enjoy. Feel free to make pull requests :)
