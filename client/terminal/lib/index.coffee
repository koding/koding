kd = require 'kd'
KDNotificationView = kd.NotificationView
isLoggedIn = require 'app/util/isLoggedIn'
AppController = require 'app/appcontroller'
globals = require 'globals'
WebTermAppView = require 'terminal/webtermappview'


module.exports = class WebTermController extends AppController

  @options = require './options'

  constructor:(options = {}, data)->

    params              = options.params or {}
    options.view        = new WebTermAppView()
                            .on 'command', @bound 'handleCommand'
    options.appInfo     =
      title             : "Terminal"
      cssClass          : "webterm"

    super options, data

    @globalNotification = null
    alreadyStarted      = no

    @getView().once 'TerminalStarted', =>
      alreadyStarted = yes
      if @globalNotification
        kd.utils.wait 300, =>
          @globalNotification.hideAndDestroy()
          kd.utils.wait 1000, =>
            kd.singletons.mainView.createGlobalNotification
              title      : "All seem good now,"
              content    : "keep coding :)"
              type       : 'green'
              closeTimer : 2000

    @getView().on 'TerminalFailed', @bound 'checkOSKiteStatus'

    # sometimes terminal is so fast we don't even need to ask oskite status
    @checkOSKiteStatus()  unless globals.useNewKites or alreadyStarted

  checkOSKiteStatus:-> @askOSKiteStatus @bound 'tellOSKiteStatus'

  askOSKiteStatus:(callback)-> kd.singletons.vmController._runWrapper 'oskite.All', callback

  tellOSKiteStatus:(err, kontainers)=>

    vms          = 0
    limits       = 0

    if err
      kd.warn err
      # title = err.message or "Something went wrong!"
      @globalNotification?.destroy()
      return @globalNotification = kd.singletons.mainView.createGlobalNotification
        title   : "Something went wrong!"
        content : "Please check back again in a few minutes."
        type    : 'yellow'

    if kontainers
      for own name, kontainer of kontainers
        for own attribute, amount of kontainer
          if attribute is 'activeVMs'
            vms += amount
          if attribute is 'activeVMsLimit'
            limits += amount

    if kontainers and vms > limits
      @globalNotification?.destroy()
      return @globalNotification = kd.singletons.mainView.createGlobalNotification
        title   : "Sorry, we can't launch your VM right now. We are experiencing an unxpected high load."
        content : "Please try again later."
        type    : 'red'

  handleQuery: (query) ->

    shouldReturn = yes
    for own key, value of query
      shouldReturn = no
      break

    return  if shouldReturn

    @getView().ready =>
      if query.chromeapp
        query.fullscreen = yes # forcing fullscreen

      @getView().handleQuery query

  ringBell: do (bell = try new Audio '/a/audio/bell.wav') -> (event) ->
    event?.preventDefault()

    { name, version } = @getOptions()

    storage = (kd.getSingleton 'appStorageController').storage name, version

    if not bell? or storage.getValue 'visualBell'
    then new KDNotificationView title: 'Bell!', duration: 100
    else bell.play()

  runCommand:(command)->
    @getView().ready =>
      @getView().runCommand command

WebTerm = {}
