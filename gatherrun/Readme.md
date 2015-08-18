# gatherrun

gatherrun is a library that collects info on how user is using their VM. This library doesn't define any metrics itself (it downloads them from a S3 server). This library provides functions to manage the workflow of getting the scripts, running them and saving the results to a datastore. The scripts are in their own repo under `github.com/koding/gather`.

## Usage

```go
// initialize `Fetcher` to download scripts from S3
fetcher := S3Fetcher{
  AccessKey:  "",
  SecretKey:  "",
  Bucket:     "gather",
  FileName:   "gather.tar",
}

// initialize `Exporter` to save results to elasticsearch
exporter := NewEsExporter("localhost", "gather")

// user and env vars
username := "indianajones"
env := "production"

// initialize `Gather` client to download (to /tmp) & run the binary and
// save the results
//
// when done, it'll delete the download binary and tar file
err := New(fetcher, exporter, env, username, options).RunAllScripts()
if err != nil {
  return err
}
```

## Interfaces

There are currently two defined interfaces: `Fetcher`, for downloading scripts from an external source and `Exporter` to save the results of ran scripts.

`S3Fetcher` implements `Fetcher`, fetches scripts from an authenticated s3 bucket. `EsExporter` implements `Exporter` saves results to ElasticSearch.

## Tests

`go test` will run the tests. There's currently no mocking for S3 operations, so tests will upload and download the check binary to a test S3 bucket.
