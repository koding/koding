# gather

gather is a library that collects info on how user is using their VM. This library doesn't define any metrics itself (it downloads them for a S3 server). This library provides functions to manage the workflow of getting the scripts, running them and saving the results to a datastore.

## Usage

```go
// initialize `Fetcher` to download scripts from S3
fetcher := gather.S3Fetcher{
  AccessKey:  "",
  SecretKey:  "",
  Bucket:     "gather-vm-metrics",
  FileName:   "check.tar",
}

// initialize `Exporter` to save results to elasticsearch
exporter := gather.NewEsExporter("localhost", "gather")

// initialize optional args to pass to client initializer below
options = gather.ClientArgs{
  Username:   "indianajones",
  InstanceId: "i-00000000",
}

// initialize `Gather` client to download (to /tmp) & run the binary and
// save the results
//
// when done, it'll delete the download binary and tar file
err := gather.New(fetcher, exporter, options).RunAllScripts()
if err != nil {
  return err
}
```

## Scripts

The scripts themselves are binary encoded into a Go binary using `go-bindata`. The main reason for this is to obuscate the scripts from the user. Some of the scripts check for abuse,if these are accesible in clear text, the user can easily circumvent it. The scripts need to be in bash and return output in format:

```
{
  "name"  : "<metric name>",
  "type"  : "<type of value>",
  "value" : <actual value>
}
```

Since scripts are binary encoded, we need to do a trick to avoid duplication. `check/checkers/common` contains the reusable functions; any function added to this file will be appened in memory to the `run-` file before the combined string is executed by Go using `bash -C` command. Only files with `run-` prefix will be run.

Even though the checkers are binary encoded and the program shared as a binary, the binary itself might contain enough info to tip people about the scripts. This is why the name of the scripts are only 3 lettes in length.

## Building

`./build.sh` will cross compile the `check` binary, tar it and upload it to S3. You'll need cross compilation enabled in Go (GOOS=linux GOARCH=386) and `aws` cli installed & configured using your credentials for this to work.

Be warned, above command is dangerous and should be used only after testing the scripts locally.

## Interfaces

There are currently two defined interfaces: `Fetcher`, for downloading scripts from an external source and `Exporter` to save the results of ran scripts.

`S3Fetcher` implements `Fetcher`, fetches scripts from an authenticated s3 bucket. `EsExporter` implements `Exporter` saves results to ElasticSearch.

## Tests

`go test` will run the tests. There's currently no mocking for S3 operations, so tests will upload and download the check binary to a test S3 bucket.
