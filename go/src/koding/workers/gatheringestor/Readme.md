# gatheringestor

gatheringestor is a http, JSON only api for saving metrics collected by gather library. It currently saves them to Mongo and sends to Datadog.

## Tests

    # from root Koding folder
    ./run gatheringestortests

## Structure

This is an example of a request:

    {
      "env"        : "prod",
      "username"   : "indianajones",
      "instanceId" : "i-00000",
      "type"       : "analytics",
      "stats"      : [{"name" : "user count", "type" : "number", "value" : "1"}]
    }

Stats is a collection of individual metric. `Value` is of type interface{} so any type of value can be sent, ie number, string, slice of strings etc.

Only numbers are sent to Datadog.

## Types

Currently there are two types of stats: abuse and analytics are implemented. When abuse stat arrives, gatheringestor tells kloud to stop VM.

## Stopping VMs

A killswitch is available by setting key `gatheringestor:globalStopDisabled` to anything in redis. When this key is set, VMs will NOT be stopped even if abuse is found in their machines.

To resume stopping VMs, delete the key.

## Exempt

Koding employees, ie those with 'staff' flag set in JAccount, are automatically exempt. I'm explicitly not checking for paying users since we've had people who pay using stolen paypal/cc and then abuse the VMs.

In addition adding username to `gatheringestor:exemptUsers` Set in redis will prevent user's machine from being stopped even if abuse is detected in their VMs.
