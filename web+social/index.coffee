argv = require('minimist') process.argv
request = require 'request'
express = require 'express'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{ social, webserver, webAndSocialProxy } = KONFIG

app = express()

app.post '/xhr', (req, res) ->
  req.pipe(
    request("http://localhost:#{ social.port }/xhr")
  ).pipe res

app.all '*', (req, res) ->
  req.pipe(
    request("http://localhost:#{ webserver.port }#{ req.path }")
  ).pipe res

app.listen webAndSocialProxy.port
