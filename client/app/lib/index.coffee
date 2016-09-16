# Make sure none of these modules are calling remote#getInstance before this file. -og
globals                = require 'globals'
kookies                = require 'kookies'
kd                     = require 'kd'
socketConnected        = require './util/socketConnected'
enableLogs             = require './util/enableLogs'
ConnectionChecker      = require './connectionchecker'
lazyrouter             = require './lazyrouter'
setupAnalytics         = require './setupanalytics'
setupChatlio           = require './setupchatlio'
setupIntercom          = require './setupintercom'
os                     = require 'os'
localStorage           = require './localstorage'

isStarted = false

require './styl/require-styles'

run = (defaults) ->

  alreadyRunning = 'already running'
  if isStarted then throw alreadyRunning else isStarted = true

  initialize defaults, bootup


bootup = ->

  # don't move following requires outside of this scope.
  # `remote` must be initialized after globals is set and ready
  # `MainController` & `Status` have some self-invoking methods
  # that depend on `remote`, and here we are. -og
  remote = require('./remote')
  # it is very important that you invoke this method before anything else does, so f important.

  globals.os = os # linux, mac or windows
  globals.keymapType = do ->
    if globals.os is 'mac' then globals.os else 'win'

  if globals.config.environment in ['dev', 'default', 'sandbox']
    global._kd      = kd
    global._remote  = remote

  if globals.currentGroup?
    globals.config.entryPoint.slug = globals.currentGroup.slug

  remote.once 'ready', ->
    globals.currentGroup           = remote.revive globals.currentGroup
    globals.userAccount            = remote.revive globals.userAccount
    globals.config.entryPoint.slug = globals.currentGroup.slug
    kd.singletons.groupsController.currentGroupData.setGroup globals.currentGroup

    setupAnalytics()  unless globals.config.environment is 'default'

  MainController = require './maincontroller'
  Status = require './status'

  # Dear sir, madam, or dolphin,
  # `Status` & `MainController` have these `registerSingleton` calls.
  # Since (at the moment) there is no easy way to track what singletons
  # we have defined or undefined; we should try to keep those calls
  # within a single space, preferably in entry point (this file).
  # That is to say, if you have registered a singleton in somewhere else,
  # and that file is not a direct dependency of this file, you are most
  # probably causing harm to sea lions and sea turtles. -og

  status         = new Status
  mainController = new MainController

  require('./routehandler')()

  firstLoad = yes

  mainController.tempStorage = {}

  ConnectionChecker.listen()

  mainController.ready ->
    setupChatlio()
    setupIntercom()


  ###
  # CONNECTIVITY EVENTS
  ###

  status.on 'bongoConnected', (account) ->
    socketConnected()
    mainController.accountChanged account, firstLoad
    firstLoad = no

  # status.on 'sessionTokenChanged', (token)->
    # this is disabled for now to test user log-out problem.
    # $.cookie 'clientId', token

  status.on 'connected', ->
    ConnectionChecker.globalNotification.hide()
    startAuthenticationInterval()
    kd.log 'kd remote connected'

  status.on 'reconnected', (options = {}) ->
    ConnectionChecker.globalNotification.hide()
    startAuthenticationInterval()
    kd.log 'kd remote re-connected'

  status.on 'disconnected', (options = {}) ->
    stopAuthenticationInterval()
    kd.log 'kd remote disconnected'

  remote.connect()

  ###
  # USER AUTHENTICATION
  ###
  authenticationInterval = null

  startAuthenticationInterval = ->
    return  if authenticationInterval

    authenticationInterval = kd.utils.repeat 20000, ->
      remote.authenticateUser()

  stopAuthenticationInterval = ->
    kd.utils.killRepeat authenticationInterval
    authenticationInterval = null

  return true


initialize = (defaults, next) ->

  kd.utils.extend globals, defaults

  globals.config.apps = globals.modules.reduce (acc, app) ->
    acc[app.name] = app
    return acc
  , {}

  lazyrouter.register globals.modules

  unless globals.config.mainUri?
    globals.config.mainUri = global.location.origin
    globals.config.apiUri  = global.location.origin

  logsEnabled = (kookies.get 'enableLogs') or not globals.config?.suppressLogs
  enableLogs logsEnabled

  next()

run()
