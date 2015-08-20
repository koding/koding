module.exports = (name              = '') ->
  { argv }     = require 'optimist'
  express      = require 'express'
  cors         = require 'cors'
  helmet       = require 'helmet'
  app          = express()

  compression = require 'compression'
  bodyParser = require 'body-parser'

  app.use compression()
  app.use bodyParser.json()
  helmet.defaults app
  app.use cors()

  KONFIG = require('koding-config-manager').load("main.#{argv.c}")
  app.get '/version', (req, res) ->
    res.send "#{KONFIG.version}"

  app.get '/healthCheck', (req, res) ->
    res.send "#{name} is running with version: #{KONFIG.version}"

  app.listen argv.p


