Mailgun with Go
===============

[![GoDoc](https://godoc.org/gopkg.in/mailgun/mailgun-go.v1?status.svg)](https://godoc.org/gopkg.in/mailgun/mailgun-go.v1)


Go library for interacting with the [Mailgun](https://mailgun.com/) [API](https://documentation.mailgun.com/api_reference.html).

Download the library

```
go get gopkg.in/mailgun/mailgun-go.v1
```

# Sending mail

You just need your domain, public and private API key from the Mailgun admin interface to get started sending using the
library:

```Go
mg := mailgun.NewMailgun(domain, apiKey, publicApiKey)
message := mailgun.NewMessage("sender@example.com", "Fancy subject!", "Hello from Mailgun Go!", "recipient@example.com")
```

# Testing

*WARNING* - running the tests will cost you money!

To run the tests various environment variables must be set. These are:

* `MG_DOMAIN` is the domain name - this is a value registered in the Mailgun admin interface.
* `MG_PUBLIC_API_KEY` is the public API key - you can get this value from the Mailgun admin interface.
* `MG_API_KEY` is the (private) API key - you can get this value from the Mailgun admin interface.
* `MG_EMAIL_ADDR` is the email address used in various tests (complaints etc.).
* `MG_EMAIL_TO` is the email address used in various sending tests.

and finally

* `MG_SPEND_MONEY` if this value is set the part of the test that use the API to actually send email
will be run - be aware *this will count on your quota* and *this _will_ cost you money*.

The code is released under a 3-clause BSD license. See the LICENSE file for more information.
