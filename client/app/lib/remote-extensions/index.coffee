
module.exports =

  initialize   : (remote) ->

    remote.api.JComputeStack = require './computestack'
    remote.api.JMachine      = require './machine'