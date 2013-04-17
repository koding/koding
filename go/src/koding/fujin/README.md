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

# Features

* Load balancing via round-robin
* Dynamic configuration
* Remote control mechanism (via kontrold). You can list, add or delete domains remotely via a custom JSON message format.
* SSL support
* Stored configuration on MongoDB instance
* Fallback mechanism for death servers


# Improvements
* custom HTML error pages (i.e. for death backends)
* wildcard support for fronted domains
* improve routing table for paths (example.com/)
* add random balancing and weighted round-robin


