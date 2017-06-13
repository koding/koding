# Specification

# Naming conventions

* `server` is listening to public connection and is responsible of routing
  public HTTP requests to clients.
* `client` is a long running process, connected to a server and running on a local machine. 
* `virtualHost` is a virtual domain that maps a domain to a single client. i.e:
  `arslan.koding.io` is a virtualhost which is mapped to my `client` running on
   my local machine.
* `identifier` is a secret token, which is not meant to be shared with others.
  An identifier is responsible of mapping a virtualhost to a client.
* `session` is a single TCP connection which uses the library `yamux`. A
  session can be created either via `yamux.Server()` or `yamux.Client`
* `stream` is a `net.Conn` compatible `virtual` connection that is multiplexed
  over the `session`. A session can have hundreds of thousands streams
* `control connection` is a single `stream` which is used to communicate and
  handle messaging between server and client. It uses a custom protocol which
  is JSON encoded.
* `tunnel connection` is a single `stream` which is used to proxy public HTTP
  requests from the `server` to the `client` and vice versa. A single `tunnel`
  connection is created for every single HTTP requests.
* `public connection` is a connection from a remote machine to the `server`
* `ControlHandler` is a http.Handler which listens to requests coming to
  `/_controlPath_/`. It's used to setup the initial `session` connection from
  `client` to `server`. And creates the `control connection` from this session.
  server and client, and also for all additional new tunnel. It literally
  captures the incoming HTTP request and hijacks it and converts it into RAW TCP,
  which then is used as the foundation for all yamux `sessions.`


# Server
1. Server is created with `NewServer()` which returns `*Server`, a `http.Handler`
   compatible type. Plug into any HTTP server you want. The root path `"/"` is
   recommended to listen and proxy any tunnels. It also listens to any request
   coming to `ControlHandler`
2. Tunneling is based on virtual hosts. A virtual hosts is identified with an
   unique identifier. This identifier is the only piece that both client and
   server needs to known ahead. Think of it as a secret token.
3. To add a virtual host, call `server.AddHost(virtualHost, identifier)`. This
   step needs to be done from the server itself. This can be could manually or
   via custom auth based HTTP handlers, such as "/addhost", which adds
   virtualhosts and returns the `identifier` to the requester (in our case `client`)
4. A DNS record and it's subdomains needs to point to a `server`, so it can
   handle virtual hosts, i.e: `*.example.com` is routed to a server, which can
   handle `foo.example.com`, `bar.example.com`, etc..


# Client

1. Client is created with `NewClient(serverAddr, localAddr)` which returns a
   `*Client`. Here `serverAddr` is the TCP address to the server. `localAddr`
  is the server in which all public requests are forwarded to. It's optional if
  you want it to be done dynamically
2. Once a client is created, it starts with `client.Start(identifier)`. Here
   `identifier` is needed upfront. This method creates the initial TCP
  connection to the server. It sends the identifier back to the server. This
  TCP connection is used as the foundation for `yamux.Client()`. Once a yamux
  session is established, we are able to use this single connection to have
  multiple streams, which are multiplexed over this one connection.  A `control
  connection` is created and client starts to listen it.  `client.Start` is
  blocking.

# Control Handshake

1. Client sends a `handshakeRequest` over the `control connection` stream
2. The server sends back a `handshakeResponse` to the client over the `control connection` stream
3. Once the client receives the `handshakeResponse` from the server, it starts
   to listen from the `control connection` stream.
4. A `control connection` is json.Encoder/Decoder both for server and client


# Tunnel creation
1. When the server receives a public connection, it checks the HTTP host
   headers and retrieves the corresponding identifier from the given host.
2. The server retrieves the `control connection` which was associated with this
   `identifier` and sends a `ControlMsg` message with the action
   `RequestClientSession`. This message is in the form of:

		type ControlMsg struct {
			Action    Action            `json:"action"`
			Protocol  TransportProtocol `json:"transportProtocol"`
			LocalPort string            `json:"localPort"`
		}

	Here the `LocalPort` is read from the HTTP Host header. If absent a zero
    port is sent and client maps it to the local server running at port 80, unless
	the `localAddr` is specified in `client.Start()` method. `Protocol` is
    reserved for future features.
3. The server immediately starts to listen(accept) to a new `stream`. This is
   blocking and it waits there.
4. When the client receives the `RequestClientSession` message, it opens a new
   `virtual` TCP connection, a `stream` to the server.
5. The server which was waiting for a new stream in step 3, establish the stream.
6. The server copies the request over the stream to the client.
7. The client copies the request coming from the server to the local server and
   copies back the result to the server
8. The server reads the response coming from the client and returns back it to
   the public connection requester

