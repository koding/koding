# kontrol-api


kontrol-api is an internal WEB API endpoint that let you interact with the
`kontrold` server. It is mostly a RESTful api.


Currently kontrold is controlling the following resources of Koding:

* workers: A worker is a process that is communicating directly via the kontrold server. 
* proxies: A proxy is an entity needed for load balancing of `fujin` proxy-handler.
Fujin is basically a reverse proxy that get all the url routes
information via kontrold.

## Workers

The client can get necessary information from a sucessfull GET requests
A sucessfull ouput will give a list of workers. You can use query based filters:

```
GET /workers
GET /workers?hostname=foo
GET /workers?status=bar
GET /workers?hostname=foo&status=bar
```

An example output of `GET /workers`

```
[
  {
    "name": "email",
    "uuid": "9f830283773a14e1d9f4b0235f5e515a",
    "hostname": "54.234.39.127-2000",
    "version": 2000,
    "timestamp": "2013-04-11T17:16:12Z",
    "pid": 12291,
    "status": 1,
    "state": "running"
  },
  {
    "name": "guestCleanup",
    "uuid": "b0c3561107fa6c18f46d050c0b2dc953",
    "hostname": "54.234.39.127-2000",
    "version": 2000,
    "timestamp": "2013-04-11T17:16:12Z",
    "pid": 12393,
    "status": 1,
    "state": "running"
  }
]
```


You can also get the information for a single worker via it's `uuid` value:

```
GET /workers/{uuid}
```

An example of `GET /workers/9f830283773a14e1d9f4b0235f5e515a`

```
[
  {
    "name": "email",
    "uuid": "9f830283773a14e1d9f4b0235f5e515a",
    "hostname": "54.234.39.127-2000",
    "version": 2000,
    "timestamp": "2013-04-11T17:19:22Z",
    "pid": 12291,
    "status": 1,
    "state": "running"
  }
]
```

You can change the state of the worker. Current state change actions are:

* start
* stop
* kill

To be able to make a state change you need the `uuid` of the worker (which you
can obtain via the respectively GET requests):

```
PUT /workers/{uuid}/{action}

```


Finally you can delete a worker via a DELETE request with uuid as resource.
Please use this with caution. Use this if you know what you want.

```
DELETE /workers/{uuid}
```

## Proxies

The client can get necessary information from a sucessfull GET requests
A sucessfull ouput will give a list of registered fujin proxy handlers. 

```
GET /proxies

```

An example output of `GET /proxies` is:

```
[
  {
    "Uuid": "mahlika.local-915",
    "Keys": ["1", "2", "4"]
  },
  {
    "Uuid": "amazon-ec2-916",
    "Keys": ["2", "5"]
  }
]
```

If you start fujin for the first time, it will register itself to kontrold with
a unique uuid. This will be printed to the terminal.  Currently the `uuid` is
created as `<hostname>-<version>` where `version` is the content of the file
`VERSION` in the base koding dir. The `uuid` can be changed in the future. It's
unique (means if you you can't another proxy with the same uuid).


Therefore you can create a default configuration and put the necessary urls
into it. And then when the proxy starts it will fetch the configuration you
have been created already.


To create an entity for the the given `uuid`:

```
POST /proxies {"uuid": "mahlika.local-916"}
```

To  delete an entity for the the given `uuid`:

```
DELETE /proxies/mahlika.local-915

```
To create (populate) the proxyies you have to make a POST request with a given key, host and hostdata:

```
POST /proxies/mahlika.local-915 {"key": "string", "host":"ip:port", "hostdata": "optional data"}
```

An example to create a key with `2`, host with `localhost:8009` and an optional
data field hostdata with `FromKontrolAPI` is:

```
POST /proxies/mahlika.local-915 {"key": "2", "host":"localhost:8009", "hostdata": "FromKontrolAPI"}
```

To get details about a given proxy you can make uuid calls via it's `uuid`
value. Also you can can use and combine query based filters:

```
GET /proxies/{uuid}
GET /proxies/{uuid}?key=2
GET /proxies/{uuid}?host=localhost:8002
GET /proxies/{uuid}?hostdata=FromKontrolAPI
```

An example of `GET /proxies/{uuid}`

```
[
  {
    "Key": "1",
    "Host": "localhost:8003",
    "Hostdata": "FromKontrolAPI"
  },
  {
    "Key": "1",
    "Host": "localhost:8002",
    "Hostdata": "FromKontrolAPI"
  },
  {
    "Key": "2",
    "Host": "localhost:8002",
    "Hostdata": "FromKontrolAPI"
  },
  {
    "Key": "4",
    "Host": "localhost:8005",
    "Hostdata": "FromKontrolAPI"
  }
]
```


