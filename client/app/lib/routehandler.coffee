debug          = (require 'debug') 'app:routes'

kd             = require 'kd'
KDRouter       = kd.Router

remote         = require './remote'
globals        = require 'globals'

lazyrouter     = require './lazyrouter'
whoami         = require './util/whoami'
nick           = require './util/nick'
showError      = require 'app/util/showError'

ShortcutsModal = require 'app/shortcuts/shortcutsmodalview'

getAction = (formName) -> switch formName
  when 'login'    then 'log in'
  when 'register' then 'register'

handleRoot = ->

  { router }     = kd.singletons
  { entryPoint } = globals.config

  router.handleRoute router.getDefaultRoute(), { entryPoint }


routerReady = (fn) ->
  { router } = kd.singletons
  if router then fn() else KDRouter.on 'RouterIsReady', fn


createSectionHandler = (sec) ->
  routerReady ->
    ({ params:{ name, slug }, query }) ->
      { router } = kd.singletons
      router.openSection slug or sec, name, query


module.exports = -> lazyrouter.bind 'app', (type, info, state, path, ctx) ->

  switch type
    when 'logout'
      kd.singletons.mainController.doLogout()

    when 'login', 'register'
      { query:{ redirectTo } } = info
      if redirectTo
        redirectTo = "/#{redirectTo}"  unless redirectTo[0] is '/'
        kd.singletons.router.handleRoute redirectTo
      else handleRoot()

    when 'home' then handleRoot()

    when 'teams'
      document.cookie = 'clientId=false'
      location.reload()

    when 'reset'
      recoverPath = ctx
      recoverPath.clear()
      kd.singletons.mainController.doLogout()
      global.location.href = path

    when 'request-collaboration'
      { nickname, channelId } = info.params
      requestCollaboration { nickname, channelId }

    when 'shortcuts'
      new ShortcutsModal


requestCollaboration = (options = {}) ->

  { nickname, channelId } = options
  debug 'requestCollaboration', options

  kd.singletons.mainController.ready ->

    if nickname is nick()
      return kd.singletons.router.back()

    kd.utils.defer -> kd.singletons.router.handleRoute '/IDE'

    me = whoami()
    debug 'whoami?', me
    me.pushNotification
      receiver: nickname
      channelId: channelId
      action: 'COLLABORATION_REQUEST'
      senderUserId: me._id
      senderAccountId: me.socialApiId
    , (err) ->
      debug 'pushNotification result', err
      showError err
      kd.singletons.router.back()
