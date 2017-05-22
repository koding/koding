globals                = require 'globals'
kookies                = require 'kookies'
kd                     = require 'kd'
enableLogs             = require './util/enableLogs'
cleanup                = require './util/cleanup'
ConnectionChecker      = require './connectionchecker'
lazyrouter             = require './lazyrouter'
setupAnalytics         = require './setupanalytics'
setupChatlio           = require './setupchatlio'
setupIntercom          = require './setupintercom'
os                     = require 'os'
localStorage           = require './localstorage'

isStarted = false

require 'app/styl'
require('./util/ping')()

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

  console.log 'Application loaded with browser info:', require 'bowser'
  console.log 'Initial Payload size:', JSON.stringify(globals).length

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

  status         = new Status
  mainController = new MainController

  require('./routehandler')()

  firstLoad = yes

  ConnectionChecker.listen()

  mainController.ready ->
    setupChatlio()
    require('./setupcountly')()
    setupIntercom()


  ###
  # CONNECTIVITY EVENTS
  ###

  status.on 'bongoConnected', (account) ->
    globals.backendIsConnected = yes
    mainController.accountChanged account, firstLoad
    firstLoad = no

  status.on 'connected', ->
    ConnectionChecker.globalNotification.hide()
    kd.log 'kd remote connected'

  status.on 'reconnected', (options = {}) ->
    ConnectionChecker.globalNotification.hide()
    kd.log 'kd remote re-connected'

  status.on 'disconnected', (options = {}) ->
    kd.log 'kd remote disconnected'

  remote.connect()

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
  cleanup()
  next()

run()
