# Compile & Run

Compile the binary

```
cd kontrolproxy/
go build
```

Start kontrol proxy 

```
./kontrolproxy -c "-kontrol-prod"
```

By default proxy starts with ports http (80) and https (443). And  You can change
them easily in the main.{config}.coffee files under the section kontrold/proxy


# Usage of Kontrol Proxy

KontrolProxy first tries himself to register to kontrol. After an "updateProxy"
message it fetches all necessary routing configurations from the mongodb and
stores them in the memory. Kontroldaemon and mongodb are necessaries to run
kontrol proxy.

Every single lookup is made on these values. Each request just creates a single
struct and every single function uses pointers to these struct, which basically
makes the proxy very fast. 

* Dynamic configuration

Every worker which has a port can be registered automatically to kontrol proxy
via the kontrol processes wrapper. For example we use webserver and gobroker
for that case. Kontrol adds them to proxy automatically everytime they start.

* RESTful API for configurations

Kontrolproxy has a powerful restful api that lets you directly remove, change,
update or add any resource it uses. For more info look at the kontrolapi readme
please. 

* Load balancing via round-robin and random

Each host is defined by their `servicename` and `key`. You can add several
hosts to a single `key`. If kontrolproxy detects that it has more than one host
it will use round-robin balancing between your servers. The only exception for
this is the 'broker' process. Round-robin for broker is disabled.

* SSL support

Kontrolproxy has support for SSL. It looks for the files `cert.pem` and
`key.pem` in the same directory it was executed. If it finds both files and the
files are correct it starts a seperate server which listens to https requests.

* Websocket support

Kontrolproxy has support for websocket. It automatically detects it and uses
hijacking for to reach the underlying tcp connection.

* Stored configuration on MongoDB instance with in built cache

All the configuration is stored in a mongodb instance. However lookups are made
on a loaded variable in the memory. The in-memory lookup is using a timeout of
20 seconds. That means after 20 seconds the lookup is made again via mongodb.

* Builtin firewall

Kontrolproxy has `rules` to support basic firewalling for certain rules.
Currently you can filter visits by IP regex and Countries. Each rule can be
either a whitelist or a blacklist. 


* Fallback mechanism for death servers

Proxy checks the health of a server before it tries to forward the incoming
request to the target host. If there are several hosts in an array, it will
choose the next one, until all hosts are checked. If all servers are dead the
default maintenance page is showed up.

* Custom HTML error pages (i.e. for death backends)

Proxy shows custom html pages for certain scenarios, like 404, 410, not active
Ms or secure pages. These are currently only used fr Koding services, but will
be personalizable for VM's too.

# Improvements

* wildcard support for fronted domains
* improve routing table for paths (example.com/)
* other loadbalance options, like weighted round-robin


