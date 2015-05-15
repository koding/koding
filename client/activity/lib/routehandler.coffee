lazyrouter = require 'app/lazyrouter'

handlers = require './routehandlers'

module.exports = -> lazyrouter.bind 'activity', (type, info, state, path, ctx) ->

  handle = (name) -> handlers["handle#{name}"](info, ctx, path, state)

  handle type

