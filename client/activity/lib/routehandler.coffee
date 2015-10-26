kd                        = require 'kd'
React                     = require 'kd-react'
createHistory             = require 'history/lib/createHistory'
createLocation            = require 'history/lib/createLocation'
handlers                  = require './routehandlers'
lazyrouter                = require 'app/lazyrouter'
isReactivityEnabled       = require 'app/util/isReactivityEnabled'
{ RoutingContext, match } = require 'react-router'

module.exports = -> lazyrouter.bind 'activity', (type, info, state, path, ctx) ->

  handle = (name) -> handlers["handle#{name}"](info, ctx, path, state)

  reactivityRoutes = [
    'SingleChannel'
    'SinglePost'
    'SingleChannelWithSummary'
    'SinglePostWithSummary'
    'PrivateMessages'
  ]

  # since `isReactivityEnabled` flag checks roles from config,
  # wait for mainController to be ready to call `isReactivityEnabled`
  # FIXME: Remove this call before public release. ~Umut
  kd.singletons.mainController.ready ->

    if type in reactivityRoutes
      if isReactivityEnabled()
      then handleReactivity info, ctx
      # unless reactivity is enabled redirect reactivity routes to `Public`
      else ctx.handleRoute '/Activity/Public'
    else handle type


###*
 * Renders with reacth router.
###
handleReactivity = ({ query }, router) ->

  routes = require './reactivityroutes'

  location = createLocation router.currentPath

  activityView (view) ->

    match { routes, location }, (err, redirectLocation, renderProps) ->
      React.render(
        <RoutingContext {...renderProps} />
        view.reactivityContainer.getElement()
      )


activityView = (callback) ->
  {appManager} = require('kd').singletons
  appManager.open 'Activity', (app) ->
    view = app.getView()
    view.switchToReactivityContainer()
    callback view


