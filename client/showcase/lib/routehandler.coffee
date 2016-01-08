lazyrouter = require 'app/lazyrouter'
kd = require 'kd'


module.exports = -> lazyrouter.bind 'showcase', (type, info, state, path, ctx) ->

  handlers = require './routehandlers'

  handle = (name) -> handlers["handle#{name}"](info, ctx, path, state)

  handle type
