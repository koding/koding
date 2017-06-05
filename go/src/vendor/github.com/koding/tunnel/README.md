# Tunnel [![GoDoc](http://img.shields.io/badge/go-documentation-blue.svg?style=flat-square)](http://godoc.org/github.com/koding/tunnel) [![Go Report Card](https://goreportcard.com/badge/github.com/koding/tunnel)](https://goreportcard.com/report/github.com/koding/tunnel) [![Build Status](http://img.shields.io/travis/koding/tunnel.svg?style=flat-square)](https://travis-ci.org/koding/tunnel)

Tunnel is a server/client package that enables to proxy public connections to
your local machine over a tunnel connection from the local machine to the
public server. What this means is, you can share your localhost even if it
doesn't have a Public IP or if it's not reachable from outside. 

It uses the excellent [yamux](https://github.com/hashicorp/yamux) package to
multiplex connections between server and client.

The project is under active development, please vendor it if you want to use it.

# Usage

The tunnel package consists of two parts. The `server` and the `client`. 

Server is the public facing part. It's type that satisfies the `http.Handler`.
So it's easily pluggable into existing servers. 


Let assume that you setup your DNS service so all `*.example.com` domains route
to your server at the public IP `203.0.113.0`. Let us first create the server
part:

```go
package main

import (
	"net/http"

	"github.com/koding/tunnel"
)

func main() {
	cfg := &tunnel.ServerConfig{}
	server, _ := tunnel.NewServer(cfg)
	server.AddHost("sub.example.com", "1234")
	http.ListenAndServe(":80", server)
}
```

Once you create the `server`, you just plug it into your server. The only
detail here is to map a virtualhost to a secret token. The secret token is the
only part that needs to be known for the client side.

Let us now create the client side part:

```go
package main

import "github.com/koding/tunnel"

func main() {
	cfg := &tunnel.ClientConfig{
		Identifier: "1234",
		ServerAddr: "203.0.113.0:80",
	}

	client, err := tunnel.NewClient(cfg)
	if err != nil {
		panic(err)
	}

	client.Start()
}
```

The `Start()` method is by default blocking. As you see you, we just passed the
server address and the secret token. 

Now whenever someone hit `sub.example.com`, the request will be proxied to the
machine where client is running and hit the local server running `127.0.0.1:80`
(assuming there is one). If someone hits `sub.example.com:3000` (assume your
server is running at this port), it'll be routed to `127.0.0.1:3000`

That's it. 

There are many options that can be changed, such as a static local address for
your client. Have alook at the
[documentation](http://godoc.org/github.com/koding/tunnel)


# Protocol

The server/client protocol is written in the [spec.md](spec.md) file. Please
have a look for more detail.


## License

The BSD 3-Clause License - see LICENSE for more details
