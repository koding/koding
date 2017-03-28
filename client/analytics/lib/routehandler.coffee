kd = require 'kd'
lazyrouter = require 'app/lazyrouter'

module.exports = -> lazyrouter.bind 'analytics', (type, info, state, path, ctx) ->

  kd.singletons.appManager.open 'Analytics'
