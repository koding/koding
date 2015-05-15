# gather

gather is a library that collects metrics on how users use their VM. This library doesn't define any metrics itself (it downloads thems for a S3 server). This library provides functions to manage the workflow of getting the scripts, running them and saving the results to a datastore.

## Quickstart

```go
// initialize `Fetcher` to download scripts
fetcher := gather.S3Fetcher{
  AccessKey:  "",
  SecretKey:  "",
  Bucket:     "gather-vm-metrics",
  ScriptFile: "latest.tar",
}

// initialize `Exporter` to save results
exporter := gather.EsExporter{Host:"localhost", Index:"gather"}

// initialize `Client` to download the scripts and save the results.
err := gather.NewClient(fetcher, exporter).RunAllScripts()
if err != nil {
  return err
}

// cleanup when done, ie. delete download scripts IMPORTANT!
defer gather.Cleanup()
```

## Scripts

The metric scripts are stored in s3 so it's easier to extend without having to deploy a new version of this library each time. The scripts can be written in any language, they just need to be executable and return an output in the format:

```
{
  'category' : '<metric category>',
  'name'     : '<metric name>',
  'type'     : '<type of value>',
  'value'    : <actual value>
}
```

## Interfaces

There are currently two defined interfaces: `Fetcher`, for downloading scripts from an external source and `Exporter` to save the results of ran scripts.

`S3Fetcher` implements `Fetcher`, fetches scripts from an authenticated s3 bucket. `EsExporter` implements `Exporter` saves results to ElasticSearch.
