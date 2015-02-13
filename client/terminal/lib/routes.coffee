kd = require 'kd'
registerRoutes = require 'app/util/registerRoutes'
isLoggedIn = require 'app/util/isLoggedIn'

module.exports = ->

  registerRoutes 'Terminal',
    '/:name?/Terminal' : (routeInfo, state, path) ->
      if !isLoggedIn()
        kd.singletons.router.handleRoute "/Login"
      else
        kd.singletons.router.handleRoute path.replace(/\/Terminal/, '/IDE')

