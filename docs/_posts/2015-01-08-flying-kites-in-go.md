---
layout: post
title: Kite A Go Library for Writing Distributed Microservices
image: /assets/img/blog/kites.png
author:
  name: Nitin Gupta
  email: nitin@koding.com
excerpt_separator: "<!--more-->"
---
<!--more-->
Writing web services with [Go][2] is super easy. The simple but powerful `net/http` package lets you write performant web services in a very quick way. However sometimes all you want is to write a RPC backend application. Basically you want to have many independent worker applications that are running separately, each with their own responsibility of doing certain tasks. They should accept requests and reply to them with a well defined response.

This is obvious, however it's getting difficult once you go beyond simple requirements. In real world scenarios you are going to have hundreds of applications running. You want to talk with them securely (and also authenticated). In order to talk with them securely, the first thing you need is to connect to a certain application. Now unless you have very few applications, there is no way you can remember the IP or hostname of that particular application (remember you have to many applications). Just storing all host IP's persistently is not enough, because the host IP can change (just think of EC2 instances that come and go). What you need is something you can go and ask, and get the IP for the given application, just like a DNS server.

So building a distributed system with many applications is becoming hard. The [Kite][3] library development started within
[Koding][4], but it was quickly open sourced. The main goal is to create easy, simple, and convenient to use distributed microservice applications. The Kite library itself has many detailed parts, so in this blog post I'll try to give an overview of what a Kite is capable of.

# Introducing Kite

[Kite][3] is a microservice RPC library written in Go which makes writing user friendly distributed systems easy. It aims a balance between simple/easy usage and performance. Kite is a RPC server as well as a client. It can connect to other kites and peers to communicate with each other (bidirectional). A Kite identifies itself with the following parameters (order is important):

* **Username**: Owner of the Kite, example: Brian, Fatih, Damian etc..
* **Environment**: Current environment such as "production", "testing", "staging", etc…
* **Name**: Short name identifying the type of the kite. Example: mykite, fs, terminal, etc …
* **Version**: 3-digit semantic version.
* **Region**: Current region, such as "Europe", "Asia" or some other locations.
* **Hostname**: Hostname of the Kite.
* **ID**: Unique ID that identifies a Kite. This is generated via the Kite library, however you might change it yourself.

These identifiers are important so a Kite can be distinguish and searched by others.

Kite uses [SockJS][5] to provide a WebSocket emulation over many different transports (websocket, xhr, etc..). So that means you can connect to Kite from a browser too (see our excellent [Kite.js][6]). Kite uses a modified [dnode protocol][7] for RPC messaging. The Kite protocol adds an additional session and authentication layer, so it can be used to identifies Kites easily. Under the hood it uses JWT for authentication and session information.

A Kite can discover other kites using a service discovery mechanism called Kontrol to communicate with other kites securely and with authentication. In order to use service discovery a Kite can register itself with Kontrol. This is optional but it's encouraged and heavily reflected in the [Kite API][8].

`Kontrol` is a service discovery mechanism for kites. It controls and keeps track of kites and provides a way to authenticate kite users, so they can securely talk with each other. Kontrol uses [etcd][9] for backend storage, however it can be replaced with others too (currently there is also support for [PostgreSQL][10]). Anything that satisfies the [kontrol.Storage][11] interface can be used as backend storage, thanks to the flexibility of Go's interfaces. Kontrol also has many ways of authenticating users. It is customizable so people can use their own way of Kontrol.

# How to use a Kite

Now let's dive in. Even more interesting is writing and using Kite. It's fun to write a Kite and let them talk to each other. First let me show you a Kite in the most simple form (for sake of simplicity I'm ignoring errors, but please don't do that :))

```go
    package main
    import "github.com/koding/kite"

    func main() {
        k := kite.New("first", "1.0.0")
        k.Run()
    }
```

Here we just created a kite with the name **first** and version **1.0.0**. The `Run()` method is running a server, which is blocking (just like http.Serve). This kite is now capable of receiving requests. Because no port number is assigned the OS has picked one for us automatically.

Let us assign a port now, so we can connect to it from another kite (otherwise you need to pick the assigned URL from the logs). To change the configuration of a Kite, such as Port number, the properties (such as Environment, Region, etc… you'll need to modify the `Config` fields:

```go
    package main
    import "github.com/koding/kite"

    func main() {
        k := kite.New("first", "1.0.0")
        k.Config.Port = 6000
        k.Run()
    }
```

The configuration values can be also overridden via environment variables if needed.

Let us create a second kite to talk with the first kite:

```go
    package main

    import (
        "fmt"
        "github.com/koding/kite"
    )

    func main() {
        k := kite.New("second", "1.0.0")
        client := k.NewClient("http://localhost:6000/kite")
        client.Dial()

        response, _ := client.Tell("kite.ping")
        fmt.Println(response.MustString())
    }
```

This time we connect to a new kite directly because we know the URL already. As a RPC system you need have a concept of URL paths. Kite uses simple method names, so it can be called by others. Each method is associated with a certain
handle (just like a http.Handler) The kite library has some default methods, one of them is the `kite.ping` method which returns a `pong` string as a response (it doesn't require any authentication information). The response can be anything, in any Go type that can be serialized to and from JSON, It's up to the sender. Kite has some predefined helper methods to convert the response to the given type. In this example the second kite just connects to our first kite and
calls the first kite's `kite.ping` method. We didn't send any arguments with this method (will be explained below). So if you run, you'll see:

```shell
    $ go run second.go
    pong
```

# Adding methods to Kite

Let us add our first custom method. This simple method is going to accept a number and return a squared result. The name of the method will be `square`.
To assign a function to a method just be sure it's satisfies the `kite.Handler` interface [http://godoc.org/github.com/koding/kite#Handler](http://godoc.org/github.com/koding/kite#Handler):

```go
    package main
    import "github.com/koding/kite"

    func main() {
        k := kite.New("first", "1.0.0")
        k.Config.Port = 6000
        k.Config.DisableAuthentication = true

        k.HandleFunc("square", func(r *kite.Request) (interface{}, error) {
        a := r.Args.One().MustFloat64()
        return a * a, nil
        })

        k.Run()
    }
```

Let's call it via our "second" kite:

```go
    package main
    import (
        "fmt"
        "github.com/koding/kite"
    )

    func main() {
         k := kite.New("second", "1.0.0")
        client := k.NewClient("http://localhost:6000/kite")
        client.Dial()

        response, _ := client.Tell("square", 4)
        fmt.Println(response.MustFloat64())
    }
```

As you see the only thing that has changed is the method call. When we call the "square" method we also send the number `4` with as arguments. You can send any JSON compatible Go type. Running the examples, we'll get simply:

```shell
    $ go run second.go
    16
```

It's that easy.

# Service discovery, how to find each other

Service discovery is baked into the Kite library. As said earlier, it's a very fundamental concept and is also heavily reflected via the Kite API. That means the Kite library forces the users to make use of service discovery. To be discovered by others they need to know your real identity. Basically you need to be authenticated. Authentication can be done in several ways and is defined by how Kontrol enforces it. It can disable it completely, might ask the user password (via the kite cli), could fetch a token and validate what the user provided and so on…

`kitectl` is a handy CLI program which can be used to manage kites easily via command line. We can use it (via `kitectl register` command) to authenticate our machine to Kontrol, so every kite running on our host will be authenticated by default. This command creates a `kite.key` file under the home directory, which is signed by kontrol itself. The content is not encrypted, however because it's signed we can use it to securely talk to Kontrol. So therefore every request we'll make to kontrol will be trusted by Kontrol.
Our username will be stored in Kontrol, so every other person in the world can trust us (of course assuming they also using the same Kontrol server).
Trusting Kontrol means we can trust everyone. So this is important, because they might be several other Kontrol servers on the planet, there could be one your Intranet or something that is public.

We are going to use the same previous example, but this time we are going to register the first kite to Kontrol and fetch the IP of it from the second kite:

```go
    package main
    import (
        "net/url"
        "github.com/koding/kite"
    )

    func main() {
        k := kite.New("first", "1.0.0")
        k.Config.Port = 6000
        k.HandleFunc("square", func(r *kite.Request) (interface{}, error) {
        a := r.Args.One().MustFloat64()
        return a * a, nil
        })

        k.Register(&url.URL{Scheme: "http", Host: "localhost:6000/kite"})
        k.Run()
    }
```

As you see we used the `Register()` method to register ourself to Kontrol. The only parameter we pass is our URL that others should be use to connect to us. This value will be stored in Kontrol and every other kite can fetch it from there. The `Register()` method is a special method that it's automatically re-registers itself if you disconnect/connect again. To protect Kontrol we use the [exponential backoff][12] algorithm to try slowly. Because it's also used heavily in production by Koding there are many little details and improvements like this. Also another detail here is, you don't pass Kontrol's URL while registration. Because you are already authenticated, Kontrol's URL is stored in `kite.key`. All you need is to call `Register()`.

Now let us search for the first kite and call it's `square` method.

```go
    package main
    import (
        "fmt"
        "github.com/koding/kite"
        "github.com/koding/kite/protocol"
    )

    func main() {
        k := kite.New("second", "1.0.0")

        // search a kite that has the same username and environment as us, but the
        // kite name should be "first"
        kites, _ := k.GetKites(&protocol.KontrolQuery{
        Username: k.Config.Username,
        Environment: k.Config.Environment,
        Name: "first",
        })

        // there might be several kites that matches our query
        client := kites[0]
        client.Dial()

        response, _ := client.Tell("square", 4)
        fmt.Println(response.MustFloat64())
    }
```

First we use the `GetKites()` method to fetch a list of kites that matches our query. `GetKites()` connects to Kontrol and fetches all kites with their URL's that matches the given query. The query needs to be in tree path form (same format as used in etcd), so Username and Environment needs to be given before you can search for a "first" kite. For this example we just assume there is one (which is) and pick up the first one, dial to it and run it. The output will be the same as with the previous one.

So the registration and fetching kites dynamically is a huge thing. You can design your distributed system so it can tolerate certain criterias you define yourself. One example is, you could start 10 `first` kites each registered under your name. If the second kite fetches it from Kontrol, it will get a list that contains 10 `first` kites along with their URL. Now it's all up to what the "second" kite is going to do. We can randomly pick one, we can call one by one (round-robin), we can ping all of them and select the fastest one, and so on …

So all this is left on the caller. Kontrol doesn't have any idea of how a Kite behaves, it only knows if it's connected (registered) or not. This simplicity allows the kite implementer to build more complexity on top of the protocol.

# Conclusion

The Kite library has many other small improvements and features that we haven't yet seen. For example there is Kite.js which can be used as a client side library on browsers. It also contains a node.js server equivalent (albeit not as finished as Go counterpart). It contains a tunnelproxy and reverseproxy out of the box, that can be used to multiplex kites behind a single port/app. It's being used in production by Koding so it has many performance based fixes and improvements by default.

Writing Kites and using it is the most important part. Once you start to use it, you can feel the simplicity of the API. The Kite library is easy to use because it shares the same philosophy as Go. It uses some of the best open source projects written in Go (such as etcd). Go made it simple to write a stable platform as a foundation for the Kite library. Because of the nature of Go, extending and improvement the Kite library was easy too.

I hope you get the idea and intention of this library and its capabilities and limitations. We are using and maintaining it extensively. However there are many things we want to improve too (such as providing other message protocols and transport protocols). Feel free to fork the project ([https://github.com/koding/kite](https://github.com/koding/kite)) and play around. Contributions are welcome!

Please let us know what you think of it.

[1]: {{ site.url }}/assets/img/blog/kites.png
[2]: https://golang.org/ "Go Lang"
[3]: https://github.com/koding/kite
[4]: https://koding.com/
[5]: https://github.com/sockjs/sockjs-client
[6]: https://github.com/koding/kite.js
[7]: https://github.com/substack/dnode-protocol
[8]: http://godoc.org/github.com/koding/kite
[9]: https://github.com/coreos/etcd
[10]: http://www.postgresql.org/
[11]: http://godoc.org/github.com/koding/kite/kontrol#Storage
[12]: http://en.wikipedia.org/wiki/Exponential_backoff.
