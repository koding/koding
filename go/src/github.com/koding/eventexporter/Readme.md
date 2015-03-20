# eventexporter

eventexporter is a library to export events to 3rd party services.

## Usage

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
