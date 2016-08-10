kd             = require 'kd'
KDRouter       = kd.Router

remote         = require('./remote').getInstance()
globals        = require 'globals'

lazyrouter     = require './lazyrouter'
isKoding       = require './util/isKoding'
whoami         = require './util/whoami'
nick           = require './util/nick'
showError      = require 'app/util/showError'
EnvironmentsModal       = require 'app/environment/environmentsmodal'
MachineSettingsModal    = require 'app/providers/machinesettingsmodal'

getAction = (formName) -> switch formName
  when 'login'    then 'log in'
  when 'register' then 'register'

handleRoot = ->
  # don't load the root content when we're just consuming a hash fragment
  return if global.location.hash.length > 0

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


createContentDisplayHandler = (section, passOptions = no) ->

  ({ params:{ name, slug }, query }, models, route) ->

    { router } = kd.singletons

    # don't render profile pages on team contexts.
    return router.handleNotFound()  unless isKoding()

    route = name unless route

    if models?
      router.openContent name, section, models, route, query, passOptions
    else
      router.loadContent name, section, slug, route, query, passOptions


module.exports = -> lazyrouter.bind 'app', (type, info, state, path, ctx) ->

  switch type
    when 'members'
      { params, query } = info
      (createContentDisplayHandler 'Members') info, state, path

    when 'logout'
      kd.singletons.mainController.doLogout()

    when 'login', 'register'
      { query:{ redirectTo } } = info
      if redirectTo
        redirectTo = "/#{redirectTo}"  unless redirectTo[0] is '/'
        kd.singletons.router.handleRoute redirectTo
      else handleRoot()

    when 'referrer'
      { params:{ username } } = info
      # give a notification to tell that this is a referral link here - SY
      handleRoot()

    when 'home' then handleRoot()

    when 'teams'
      document.cookie = 'clientId=false'
      location.reload()

    # this whole block is probably unnecessary, because we are not supporting
    # /(teamName|groupName) scheme anymore. We would probably just return a not
    # found here no matter what, because this block is being hit ONLY IF there
    # is no other matching route found. ~Umut
    when 'name'
      open = (routeInfo, model) ->
        switch model?.bongo_?.constructorName
          when 'JAccount'
            (createContentDisplayHandler 'Members') routeInfo, [model]
          when 'JGroup'
            (createSectionHandler 'Activity') routeInfo, model
          else
            ctx.handleNotFound routeInfo.params.name

      if state? then open.call this, info, state
      else if not info?.params?.name then open.call this, info
      else
        remote.cacheable info.params.name, (err, models, name) =>
          if models?
          then open.call this, info, models.first
          else ctx.handleNotFound info.params.name

    when 'reset'
      recoverPath = ctx
      recoverPath.clear()
      kd.singletons.mainController.doLogout()
      global.location.href = path

     when 'my-machines'
      { stackId } = info.params
      new EnvironmentsModal { selected: stackId }

    when 'request-collaboration'
      { nickname, channelId } = info.params
      requestCollaboration { nickname, channelId }

    when 'machine-settings'
      { uid, state } = info.params
      { computeController, router } = kd.singletons

      computeController.ready ->
        machine = computeController.findMachineFromMachineUId uid
        unless machine
          new kd.NotificationView { title: 'No machine found' }
          return router.handleRoute '/IDE'

        modal = new MachineSettingsModal {}, machine

        # if there is a state, it's the name of the tab of modal. Switch to that.
        modal.tabView.showPaneByName state  if state

    when 'unsubscribe'
      { opt } = info.params
      { router } = kd.singletons
      router.handleRoute "/Account/Email?unsubscribe=#{opt}"


requestCollaboration = ({ nickname, channelId }) ->

  kd.singletons.mainController.ready ->

    if nickname is nick()
      return kd.singletons.router.back()

    kd.utils.defer -> kd.singletons.router.handleRoute '/IDE'

    me = whoami()
    me.pushNotification
      receiver: nickname
      channelId: channelId
      action: 'COLLABORATION_REQUEST'
      senderUserId: me._id
      senderAccountId: me.socialApiId
    , (err) ->

      showError err
      kd.singletons.router.back()
