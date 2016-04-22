kd = require 'kd'
lazyrouter = require 'app/lazyrouter'


module.exports = -> lazyrouter.bind 'stackeditor', (type, info, state, path, ctx) ->

  kd.singletons.appManager.open 'Stackeditor'
