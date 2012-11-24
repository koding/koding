express = require 'express'

createVhost = require './createvhost'
deleteVhost = require './deletevhost'
config = require './config'

error =(err, res)->
  res.send
    type: 'error'
    message: err.message
  , 400

app = express.createServer()

app.get '/addVhost', (req, res)->
  {vhost} = req.query
  createVhost vhost, config, (err)->
    if err?
      error err, res
    else
      res.send
        type: 'success'
        message: "Added vhost: #{vhost}"

app.get '/deleteVhost', (req, res)->
  {vhost} = req.query
  deleteVhost vhost, config, (err)->
    if err?
      error err, res
    else
      res.send
        type: 'success'
        message: "Deleted vhost: #{vhost}"

app.get '/resetVhost', (req, res)->
  {vhost} = req.query
  deleteVhost vhost, config, (err)->
    console.log 'yoyooyoyooyoyoyo'
    if err?
      res.send
        type: 'error'
        message: err.message
      , 400
    else
      createVhost vhost, config, (err)->
        if err?
          error err, res
        else
          res.send
            type: 'success'
            message: "Reset vhost: #{vhost}"

app.get '*', (req, res)-> res.send 404

app.listen config.vhostConfigurator.webPort
