argv = require('minimist') process.argv
request = require 'request'
express = require 'express'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{ projectRoot, social, webserver, boxproxy, broker } = KONFIG

app = express()
app.use express.static "#{projectRoot}/website/"


app.all '/xhr*', (req, res) ->
  req.pipe(
    request("http://localhost:#{ social.port }#{ req.path }")
  ).pipe res

app.all '/subscribe*', (req, res) ->
  req.pipe(
    request("http://localhost:#{ broker.port }#{ req.path }")
  ).pipe res


app.all '*', (req, res) ->
  req.pipe(
    request("http://localhost:#{ webserver.port }#{ req.path }")
  ).pipe res

app.listen boxproxy.port
console.log "[boxproxy] listening on port #{boxproxy.port}"