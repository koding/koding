# eventexporter [![Build Status](https://travis-ci.org/koding/eventexporter.svg?branch=master)](https://travis-ci.org/koding/eventexporter)

eventexporter is a library to export events to 3rd party services.

## Usage

```go
key := "segment api token"
size := "size of events to accumulate before flushing"

event := &eventexporter.Event{
  Name: "test event",
  User: &eventexporter.User{
    Username:"indianajones", Email: "indiana@gmail.com"
  },
  Body: &eventexporter.Body{Content: "Hello world"},
  Properties: map[string]interface{}{"occupation" : "explorer" },
}

client := eventexporter.NewSegementIOExporter(key, size)
client.Send(event)
```

FakeExporter is an implementation of Exporter to be used in tests.

```go
import (
  "github.com/koding/eventexporter"
)

event := &eventexporter.Event{Name: "test event"}

client := eventexporter.NewFakeExporter()
client.Send(event)

fmt.Println(client.Events)
```
