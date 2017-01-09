module.exports = (name = '', options = {}) ->
  { argv }     = require 'optimist'
  express      = require 'express'
  cors         = require 'cors'
  helmet       = require 'helmet'
  app          = express()

  bodyParser = require 'body-parser'

  app.use bodyParser.json()
  app.use helmet()
  app.use cors()

  KONFIG = require 'koding-config-manager'
  app.get '/version', (req, res) ->
    res.send "#{KONFIG.version}"

  app.get '/healthCheck', (req, res) ->
    res.send "#{name} is running with version: #{KONFIG.version}"

  app.listen options.port
