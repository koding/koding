# gatheringestor

gatheringestor is a http, JSON only api for saving metrics collected by gather library. It currently saves them to Mongo and sends to Datadog.

gather is part of klient repo.

## Tests

    go test koding/workers/gatheringestor -test.v=true

## Structure

This is an example of a request:

    {
      "env"        : "prod",
      "username"   : "indianajones",
      "instanceId" : "i-00000",
      "stats"      : [{"name" : "user count", "type" : "number", "value" : "1"}]
    }

Stats is a collection of individual metric. `Value` is of type interface{} so any type of value can be sent, ie number, string, slice of strings etc.

Only numbers are sent to Datadog.
