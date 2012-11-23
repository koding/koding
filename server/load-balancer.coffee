{argv} = require 'optimist'
KONFIG = require argv.c.trim()
bouncy = require("bouncy")
_    = require 'underscore'
http = require 'http'
ports = KONFIG.webserver?.port
ports = [ports] unless Array.isArray(ports)
processes   = new (require "processes")

processMonitor = (require 'processes-monitor').start
  name : "loadBalancer"
  interval : 1000

# init vars
configPath       = argv.c
addresses        = (host: "localhost",port: port for port in ports)
index            = 0
loadBalancerPort = KONFIG.loadBalancer.port
heartbeat        = KONFIG.loadBalancer.heartbeat
webserver        = KONFIG.webserver
httpRedirectPort = KONFIG.loadBalancer.httpRedirect?.port

process.on 'message',(msg)->
  console.log "got msg",msg
  markServerAsDead msg.port if msg.markAsDead
  
    

markServerAsDead = (port)->
  if port
    for server in addresses when server.port is port
      server.dead = yes
      server.good = no
      console.log "webserver at port #{port} marked as dead."

getNextServer = do ->
  nextServer = 0
  ln = addresses.length
  (options, recurse, callback) ->
    [callback, recurse] = [recurse, callback]  unless callback
    recurse ?= 0
    # arr = _.min addresses,(server) -> server.ping
    srv = addresses[(nextServer++)%ln]
    # console.log 'r'+recurse
    if srv.good is no and recurse < ln
      # srv = addresses[(nextServer++)%ln]

      getNextServer options, ++recurse, callback
    else if recurse is ln-1
      callback "all servers are dead"
    else
      callback null,srv

redirect = (to,bounce)->
  res = bounce.respond()
  res.statusCode = 302
  res.setHeader('Location', to)
  res.end('Redirecting to <a href="' + to + '">' + to + '</a>')

if httpRedirectPort
  bouncy((req, bounce) -> 
    redirect "https://koding.com#{req.url}",bounce
  ).listen httpRedirectPort

bouncy((req, bounce) -> 
  getNextServer {},(err,srv)->
    if err
      console.log "all servers are dead"
    else
      bounce srv.port
      # console.log "[rq:#{i++}]served from #{srv.port}"
).listen loadBalancerPort

console.log "[HTTP-PROXY] Running load balancer on port #{loadBalancerPort} pid:#{process.pid}"
# console.log "[HTTP-PROXY] Proxying:",addresses

# if webserver
#   ports.forEach (port)->
#     runServer configPath, null, port,null


ping = (server, key)->
  timedOut = false
  timeStart = Date.now()
  a = setTimeout ->
    timedOut = true
    server.good = no
    server.slow = yes
    server.ping = Infinity
  ,100
  http.get host:server.host,port:server.port, (res) ->
    clearTimeout a
    timeElapsed = Date.now()-timeStart
    server.ping = timeElapsed
    server.slow = if timeElapsed > 50 then yes else no
    server.dead = no
    server.good = !server.slow
  .on "error", (e) ->
    clearTimeout a
    server.slow = yes
    server.dead = yes
    server.good = no
    server.ping = Infinity


if heartbeat
  setInterval ->
    addresses.forEach (server,key)->
      ping server,key
    # console.log addresses
    getNextServer {},(err,srv) -> # console.log "[HTTP-PROXY] best server:",srv
  ,heartbeat