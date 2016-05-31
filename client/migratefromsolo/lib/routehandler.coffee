kd = require 'kd'
lazyrouter = require 'app/lazyrouter'


module.exports = -> lazyrouter.bind 'migratefromsolo', (type, info, state, path, ctx) ->

  kd.singletons.mainController.ready ->
    kd.singletons.appManager.open 'IDE', ->
      kd.singletons.appManager.open 'Migratefromsolo'
