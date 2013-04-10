http         = require "http"
url          = require "url"
request      = require "request"
cluster      = require "cluster"

{argv}       = require 'optimist'
{imageProxy} = require('koding-config-manager').load("main.#{argv.c}")

if imageProxy.run

    if cluster.isMaster
        console.log "imageProxy is running on port #{imageProxy.port}"
        for i in [1..imageProxy.clusterSize]
            cluster.fork()
    else
        srv = http.createServer (req, resp)->
            {query} = url.parse req.url, yes
            if query.url
                req.pipe(request(query.url)).pipe(resp)
        srv.listen imageProxy.port
