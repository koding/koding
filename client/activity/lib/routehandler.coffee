React      = require 'kd-react'
Router     = require 'app/components/router'
Location   = require 'react-router/lib/Location'
handlers   = require './routehandlers'
lazyrouter = require 'app/lazyrouter'

module.exports = -> lazyrouter.bind 'activity', (type, info, state, path, ctx) ->

  handle = (name) -> handlers["handle#{name}"](info, ctx, path, state)

  if type is 'SingleChannel'
  then handleReactivity info, ctx
  else handle type


###*
 * Renders with reacth router.
###
handleReactivity = ({ query }, router) ->

  location = new Location router.currentPath, query
  routes = require './reactivityroutes'

  activityView (view) ->
    Router.run routes, location, (error, state) ->
      React.render(
        <Router {...state}>
          {routes}
        </Router>
        view.getElement()
      )


activityView = (callback) ->
  {appManager} = require('kd').singletons
  appManager.open 'Activity', (app) ->
    callback app.getView()


