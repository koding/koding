# gatheringestor

gatheringestor is a http, JSON only api for saving metrics collected by gather library. It currently saves them to Mongo and sends to Datadog.

gather is part of klient repo.

## Tests

    go test koding/workers/gatheringestor -test.v=true

## Structure

gatheringestor expects requests to unmarshal to the following struct:

    type GatherStat struct {
      Id         bson.ObjectId      `bson:"_id" json:"-"`
      Env        string             `bson:"env" json:"env"`
      Username   string             `bson:"username" json:"username"`
      InstanceId string             `bson:"instanceId" json:"instanceId"`
      Stats      []GatherSingleStat `bson:"stats" json:"stats"`
    }

Stats is a collection of individual metric. `GatherSingleStat#Value` is of type interface{} so any type of value can be sent, ie number, string, slice of strings etc.

    type GatherSingleStat struct {
      Name  string      `bson:"name" json:"name"`
      Type  string      `bson:"type" json:"type"`
      Value interface{} `bson:"value" json:"value"`
    }

Only numbers are sent to Datadog.
