# SMTP-API

This is a simple library to simplify the process of using [SendGrid's](https://sendgrid.com) [X-SMTPAPI](http://sendgrid.com/docs/API_Reference/SMTP_API/index.html).

[![BuildStatus](https://travis-ci.org/sendgrid/sendgrid-go.png?branch=master)](https://travis-ci.org/sendgrid/sendgrid-go)

## Examples

### New Header

```go
header := smtpapi.NewSMTPAPIHeader()
```

### Recipients

```go
header.AddTo("addTo@mailinator.com")
// or
tos := []string{"test@test.com", "test@email.com"}
header.AddTos(tos)
// or
header.SetTos(tos)
```

### [Substitutions](http://sendgrid.com/docs/API_Reference/SMTP_API/substitution_tags.html)

```go
header.AddSubstitution("key", "value")
// or
values := []string{"value1", "value2"}
header.AddSubstitutions("key", values)
//or
sub := make(map[string][]string)
sub["key"] = values
header.SetSubstitutions(sub)
```

### [Section](http://sendgrid.com/docs/API_Reference/SMTP_API/section_tags.html)

```go
header.AddSection("section", "value")
// or
sections := make(map[string]string)
sections["section"] = "value"
header.SetSections(sections)
```

### [Category](http://sendgrid.com/docs/Delivery_Metrics/categories.html)

```go
header.AddCategory("category")
// or
categories := []string{"setCategories"}
header.AddCategories(categories)
// or
header.SetCategories(categories)
```

### [Unique Arguments](http://sendgrid.com/docs/API_Reference/SMTP_API/unique_arguments.html)

```go
header.AddUniqueArg("key", "value")
// or
args := make(map[string]string)
args["key"] = "value"
header.SetUniqueArgs(args)
```

### [Filters](http://sendgrid.com/docs/API_Reference/SMTP_API/apps.html)

```go
header.AddFilter("filter", "setting", "value")
// or
filter := &Filter{
  Settings: make(map[string]string),
}
filter.Settings["enable"] = "1"
filter.Settings["text/plain"] = "You can haz footers!"
header.SetFilter("footer", filter)

```

### JSONString

```go
header.JSONString() //returns a JSON string representation of the headers
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Running Tests

````bash
go test -v
```

## MIT License
