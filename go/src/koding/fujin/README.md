# Compile & Run

Compile the binary

```
cd fujin/
go build
```

Start fujin proxy hander 

```
./fujin -c "dev"
```

This will start via http (80) and https (443). You can change them with

```
./fujin -c "dev" --port 8080 --portSSL 9090

```

# Usage of Fujin

You can test fujin with curl request. You can use the test-dummy-server to
represent backend servers:

```
go run test/proxy-dummy-server.go -p 8002
```

This will create a dummy server on localhost:8004. You can run several dummy
servers. After setting up these dummy servers you have to create configuration.
Please refer to kontrol-api for creating and managing fujin proxy configuration.

An example of using this api for the uuid `kontrol.local-2000` is:

After starting you can push new configuration via the API:

```
http POST "localhost:8000/proxies/kontrol.local-2000" key=1 host=localhost:8002
http POST "localhost:8000/proxies/kontrol.local-2000" key=1 host=localhost:8003
http POST "localhost:8000/proxies/kontrol.local-2000" key=1 host=localhost:8004
```

The POST requests above will create three backend servers that fujin will proxy
the incoming requests. It uses round-robin by default. 

* If any of the servers from the same key(in our example `1`) dies or is not
more reachable, round robin balancing will be applied only to alives one. (i.e
when the server with port 8003 dies, roundrobin will be iterating only
trough 8002 and 8004)

* If all of the servers are not more reachable, it fallbacks to
`localhost:8000`. This is not configurable currently and is hardcoded.


If you push a new host with a key greater than the previous:

```
http POST "localhost:8000/proxies/kontrol.local-2000" key=2 host=localhost:8002
```

Then fujin will automatically use the information with keys `2`. The old routes
are still available.


# Features

* Load balancing via round-robin
* Dynamic configuration
* Remote control mechanism (via kontrold). You can list, add or delete domains
remotely via a custom JSON message format.
* SSL support
* Stored configuration on MongoDB instance
* Fallback mechanism for death servers


# Improvements
* custom HTML error pages (i.e. for death backends)
* wildcard support for fronted domains
* improve routing table for paths (example.com/)
* add random balancing and weighted round-robin


