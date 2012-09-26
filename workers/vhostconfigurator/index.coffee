express = require 'express'

createVhost = require './createvhost'
config = require './config'

app = express.createServer()

app.get '/addVhost', (req, res)->
  {vhost} = req.query
  createVhost vhost, config, (err)->
    if err?
      res.send
        type: 'error'
        message: err.message
      , 400
    else
      res.send
        type: 'success'
        message: "Added vhost: #{vhost}"

app.get '*', (req, res)-> res.send 404

app.listen config.vhostConfigurator.webPort