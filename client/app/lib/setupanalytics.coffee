kd         = require 'kd'
remote     = require 'app/remote'
globals    = require 'globals'
isLoggedIn = require './util/isLoggedIn'
identified = false

setupIdentify = ->

  kd.getSingleton('mainController').on 'AccountChanged', (account) ->
    return  unless isLoggedIn() and account
    kd.utils.defer -> identifyUser account

identifyUser = (account) ->

  return  if identified
  identified = true

  { profile } = account
  return  unless profile

  { nickname } = profile

  env = globals.config.environment
  { userAgent } = window.navigator

  traits = { email: globals.userEmail, env, userAgent }

  analytics?.identify nickname, traits

setupPageAnalyticsEvent = ->

  kd.singletons.router.on 'RouteInfoHandled', (args) ->
    { path } = args
    return  unless path

    title = getFirstPartOfpath(path)
    analytics?.page(title, { title: document.title, path })

getFirstPartOfpath = (path) -> return path.split('/')[1] or path

setupRollbar = ->

  Rollbar?.configure
    payload: { client: { javascript:
      source_map_enabled:    true
      guess_uncaught_frames: true
      code_version:          globals.config.version } }

module.exports = setupAnalytics = ->

  if globals.config.sendEventsToSegment
    setupIdentify()
    setupPageAnalyticsEvent()

  setupRollbar()
