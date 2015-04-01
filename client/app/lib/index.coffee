# Make sure none of these modules are calling remote#getInstance before this file. -og
globals                = require 'globals'
kookies                = require 'kookies'
kd                     = require 'kd'
KDModalView            = kd.ModalView
KDNotificationView     = kd.NotificationView
getFullnameFromAccount = require './util/getFullnameFromAccount'
socketConnected        = require './util/socketConnected'
enableLogs             = require './util/enableLogs'
whoami                 = require './util/whoami'
ConnectionChecker      = require './connectionchecker'
lazyrouter             = require './lazyrouter'
setupAnalytics         = require './setupanalytics'
os                     = require 'os'

isStarted = false


module.exports = (defaults) ->

  if isStarted then throw 'already running' else isStarted = true

  initialize defaults, bootup


bootup = ->

  # don't move following requires outside of this scope.
  # `remote` must be initialized after globals is set and ready
  # `MainController` & `Status` have some self-invoking methods
  # that depend on `remote`, and here we are. -og
  remote = require('./remote').getInstance()
  # it is very important that you invoke this method before anything else does, so f important.

  globals.os = os # linux, mac or windows
  globals.keymapType = do ->
    if globals.os is 'mac' then globals.os else 'win'

  if globals.config.environment in ['dev', 'sandbox']
    global._kd      = kd
    global._remote  = remote

  remote.once 'ready', ->
    globals.currentGroup = remote.revive globals.currentGroup
    globals.userAccount  = remote.revive globals.userAccount

    setupAnalytics()

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

  status           = new Status
  mainController   = new MainController

  require('./routehandler')()

  currentNotif     = null
  firstLoad        = yes

  mainController.tempStorage = {}

  if /edge.koding.com/.test global.location.href
    name = getFullnameFromAccount whoami()
    modal = new KDModalView
      title            : "Hi #{name},"
      width            : 600
      overlay          : yes
      cssClass         : "new-kdmodal"
      content          : """
<div class='modalformline'>
  <p>Thanks for trying out the bleeding 'edge' of Koding features. Most of the new features here are experimental and hence prone to breaking.</p><br>

  <p>If you run into problems, we'd love to hear what went wrong and how to reproduce the error. Please send an email to <a href="mailto:edge@koding.com">edge@koding.com</a>. Note that even though this environment is experimental, your vms are the same production vms as on koding.com.</p><br>

  <p>By continuing you acknowledge the experimental nature of this environment.</p><br>
</div>
"""
      buttons          :
        "I Agree"      :
          style        : "modal-clean-green"
          callback     : -> modal.destroy()

  ###
  # CONNECTIVITY EVENTS
  ###

  status.on 'bongoConnected', (account)->
    socketConnected()
    mainController.accountChanged account, firstLoad
    firstLoad = no

  # status.on 'sessionTokenChanged', (token)->
    # this is disabled for now to test user log-out problem.
    # $.cookie 'clientId', token

  status.on 'connected', ->
    destroyCurrentNotif()
    kd.log 'kd remote connected'

  status.on 'reconnected', (options={})->
    destroyCurrentNotif()
    kd.log "kd remote re-connected"

  status.on 'disconnected', (options={})->
    kd.log "kd remote disconnected"

  remote.connect()

  ###
  # INTERNET CONNECTIVITIY
  ###

  smallDisconnectedNotif =->
    currentNotif = new KDNotificationView
      title         : "Looks like your Internet connection is down"
      type          : "tray"
      closeManually : yes
      content       : """<p>Koding will continue trying to reconnect but while your connection is down, <br> no changes you make will be saved back to your VM. Please save your work locally as well.</p>"""
      duration      : 0

  modals =
    small :
      disconnected : smallDisconnectedNotif

  showNotif = (size, state)->
    destroyCurrentNotif()
    modal = modals[size][state]
    modal?()

  destroyCurrentNotif =->
    currentNotif?.destroy()
    currentNotif = null

  if global.navigator.onLine?
    kd.utils.repeat 10000, ->
      if global.navigator.onLine
        destroyCurrentNotif()  if currentNotif
      else
        showNotif "small", "disconnected"  unless currentNotif
  else
    global.connectionCheckerReponse = ->

    kd.utils.repeat 30000, ->
      item = new ConnectionChecker
        jsonp       : "connectionCheckerReponse"
        crossDomain : yes
        fail        : -> showNotif "small", "disconnected"  unless currentNotif
      , "https://s3.amazonaws.com/koding-ping/ping.json"

      item.ping -> destroyCurrentNotif()  if currentNotif

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

  logsEnabled = (kookies.get 'enableLogs') or !globals.config?.suppressLogs
  enableLogs logsEnabled

  next()
