debug = require('debug')('app:lazyrouter')
Emitter = require('events').EventEmitter
registerRoutes = require './util/registerRoutes'
_ = require 'lodash'

emitter = new Emitter


dispatch = (m, type, info, state, path) ->

  name = m.name.toLowerCase()

  debug 'dispatch', { name, type, info, state, path }

  emitter.emit name, type, info, state, path, this


exports.bind = (name, fn) ->
  emitter.on name, fn


exports.register = (modules) ->

  modules.forEach (m) ->

    return  unless m.routes

    routes           = {}
    endpoints        = Object.keys m.routes

    endpoints.forEach (endpoint) ->
      type = m.routes[endpoint]
      routes[endpoint] = _.partial dispatch, m, type

    registerRoutes m.name, routes

  return true
