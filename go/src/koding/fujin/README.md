# Compile & Run

Compile the binary

```
cd proxy-handler/
go build
```

Start the proxy handler

```
./proxy-handler
```

This will start via http (80) and https (443). You can change them with

```
./proxy-handler --port 8080 --portSSL 9090

```


# Features

* Load balancing via round-robin
* Dynamic configuration
* Remote control mechanism (via kontrold). You can list, add or delete domains remotely via a custom JSON message format.
* SSL support


# Improvements
* use redis as configuration backend (instead of JSON file)
* detect death backends and remove (or flag) them from the config
* custom HTML error pages (i.e. for death backends)
* wildcard support for fronted domains
* improve routing table for paths (example.com/)
* add random balancing and weighted round-robin


