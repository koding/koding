'use strict'

module.exports = class ListenerTree

  {assureAt, pushAt, getAt} = require 'jspath'

  constructor:->
    # we need a true dictionary; don't inherit from Object.prototype
    @tree = Object.create null

  on:(routingKey, listener)->
    assureAt @tree, routingKey, []
    pushAt @tree, routingKey, listener
    @

  off:(routingKey, listener)->
    console.log 'ListenerTree#off is still unimplemented.'
    @

  emit:(routingKey, rest...)->
    listeners = getAt @tree, routingKey
    params = rest.map (param) ->
      try JSON.parse param
      catch e then param
    if listeners?.length
      listener params... for listener in listeners
    @
