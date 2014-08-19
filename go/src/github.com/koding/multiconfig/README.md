# Multiconfig [![GoDoc](https://godoc.org/github.com/koding/multiconfig?status.svg)](http://godoc.org/github.com/koding/multiconfig) [![Build Status](https://travis-ci.org/koding/multiconfig.svg)](https://travis-ci.org/koding/multiconfig) 

Load configuration from multiple sources. Multiconfig makes loading/parsing
from different configuration sources an easy task. The problem with any app is
that with time there are many options how to populate a set of configs.
Multiconfig makes it easy by dynamically creating all necessary options.
Checkout the example below to see it in action.

## Install

```bash
go get github.com/koding/multiconfig
```

## Usage and Examples

Lets define and struct that defines our configuration 

```go
type Server struct {
	Name    string
	Port    int
	Enabled bool
	Users   []string
}
```

Load the configuration into multiconfig:

```go
// Create a new constructor without or with an initial config file
m := multiconfig.New()
m := multiconfig.NewWithPath("config.toml") // supports TOML and JSON

// Get an empty struct for your configuration
serverConf := new(Server)

// Populated the serverConf struct
err := m.Load(serverConf) // Check for error
m.MustLoad(serverConf)    // Panic's if there is any error
```

Run your app:

```sh
# Loads from config.toml 
$ app 

# Override any config easily with environment variables, environment variables
# are automatically generated in the form of STRUCTNAME_FIELDNAME
$ SERVER_PORT=4000 SERVER_NAME="koding" app 

# Or pass via flag. Flags are also automatically generated based on the field
# name
$ app -port 4000 -users "gopher,koding"

# Print dynamically generated flags and environment variables:
$ app -help
Usage of app:
  -enabled=true: Change value of Enabled.
  -name=Koding: Change value of Name.
  -port=6060: Change value of Port.
  -users=[ankara istanbul]: Change value of Users.

Generated environment variables:
   SERVER_NAME
   SERVER_PORT
   SERVER_ENABLED
   SERVER_USERS
```


## License

The MIT License (MIT) - see LICENSE.md for more details
