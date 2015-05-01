Atlas Go
========
[![Latest Version](http://img.shields.io/github/release/hashicorp/atlas-go.svg?style=flat-square)][release]
[![Build Status](http://img.shields.io/travis/hashicorp/atlas-go.svg?style=flat-square)][travis]
[![Go Documentation](http://img.shields.io/badge/go-documentation-blue.svg?style=flat-square)][godocs]

[release]: https://github.com/hashicorp/atlas-go/releases
[travis]: http://travis-ci.org/hashicorp/atlas-go
[godocs]: http://godoc.org/github.com/hashicorp/atlas-go

Atlas Go is the official Go client for [HashiCorp's Atlas][Atlas] service.

Usage
-----
### Authenticating with username and password
Atlas Go can automatically generate an API authentication token given a username
and password. For example:

```go
client := atlas.DefaultClient()
token, err := client.Login("username", "password")
if err != nil {
  panic(err)
}
```

The `Login` function returns an API token that can be used to sign requests.
This function also sets the `Token` parameter on the Atlas Client, so future
requests are signed with this access token.

**If you have two-factor authentication enabled, you must manually generate an
access token on the Atlas website.**

### Usage with on-premise Atlas
Atlas Go supports on-premise Atlas installs, but you must specify the URL of the
Atlas server in the client:

```go
client, err := atlas.NewClient("https://url.to.your.atlas.server")
if err != nil {
  panic(err)
}
```

Example
-------
The following example generates a new access token for a user named "sethvargo",
generates a new Application named "frontend", and uploads the contents of a path
to said application with some user-supplied metadata:

```go
client := atlas.DefaultClient()
token, err := client.Login("sethvargo", "b@c0n")
if err != nil {
  log.Fatalf("err logging in: %s", err)
}

app, err := client.CreateApp("sethvargo", "frontend")
if err != nil {
  log.Fatalf("err creating app: %s", err)
}

metadata := map[string]interface{
  "developed-on": runtime.GOOS,
}

data, size := functionThatReturnsAnIOReaderAndSize()
version, err := client.UploadApp(app, metadata, data, size)
if err != nil {
  log.Fatalf("err uploading app: %s", err)
}

// version is the unique version of the application that was just uploaded
version
```


FAQ
---
**Q: Can I specify my token via an environment variable?**<br>
A: All of HashiCorp's products support the `ATLAS_TOKEN` environment variable.
You can set this value in your shell profile or securely in your environment and
it will be used.

**Q: How can I authenticate if I have two-factor authentication enabled?**<br>
A: If you have two-factor authentication enabled, you must generate an access
token via the Atlas website and pass it to the client initialization. The Atlas
Go client does not support generating access tokens from two-factor
authentication enabled accounts via the command line.

**Q: Why do I need to specify the "user" for an Application, Build Configuration,
and Runtime?**<br>
A: Since you can be a collaborator on different projects, we wanted to have
absolute clarity around which artifact you are currently interacting with.


Contributing
------------
To hack on Atlas Go, you will need a modern [Go][] environment. To compile the `atlas-go` binary and run the test suite, simply execute:

```shell
$ make
```

This will compile the `atlas-go` binary into `bin/atlas-go` and run the test suite.

If you just want to run the tests:

```shell
$ make test
```

Or to run a specific test in the suite:

```shell
go test ./... -run SomeTestFunction_name
```

Submit Pull Requests and Issues to the [Atlas Go project on GitHub][Atlas Go].

[Atlas]: https://atlas.hashicorp.com "HashiCorp's Atlas"
[Atlas Go]: https://github.com/hashicorp/atlas-go "Atlas Go on GitHub"
[Go]: http://golang.org "Go the language"
